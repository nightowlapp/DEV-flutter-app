// lib/features/map/presentation/map_images_registry.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// same helper you use in CustomNetworkImage
import 'package:nightowlcode/core/storage/storage_url.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

import '../../../../shared/constants/icons.dart';

class MapImageRegistry {
  MapImageRegistry._();
  static final MapImageRegistry instance = MapImageRegistry._();

  final _loaded = <String>{};

  static const double _borderWidth = 8.0;
  static const ui.Color _borderOpenColor = green;
  static const ui.Color _borderSoonColor = yellow; //TODO implement.
  static const ui.Color _borderClosedColor = red;

  ui.Color _borderColorForFriend(String id) {
    // Expected patterns:
    //  - friend_avatar_<uid>_<partyStatus>
    //  - (optionally later) friend_avatar_<partyStatus>
    //
    // We know valid status strings:
    const validStatuses = <String>{
      'out_tonight',
      'house_party',
      'pregame',
      'recovering',
      'still_planning',
    };

    final parts = id.split('_');
    if (parts.length < 3) {
      return greyLighter;
    }

    // Try every suffix from index 2 onward:
    //
    // friend_avatar_abc123_out_tonight
    // parts = [friend, avatar, abc123, out, tonight]
    //
    // i=2 -> "abc123_out_tonight" (no match)
    // i=3 -> "out_tonight"        (match ✅)
    for (int i = 2; i < parts.length; i++) {
      final candidate = parts.sublist(i).join('_');
      if (!validStatuses.contains(candidate)) continue;

      switch (candidate) {
        case 'out_tonight':
          return purpleAccent;
        case 'house_party':
          return blue;
        case 'pregame':
          return orange;
        case 'recovering':
          return red;
        case 'still_planning':
        default:
          return greyLighter;
      }
    }

    // If no suffix matches, fall back
    return greyLighter;
  }


  Future<void> syncIdToUrl({
    required MapboxMap map,
    required Map<String, String> images,

    // Treat this as the *logical* diameter (in CSS px / map px)
    int maxSize = 60,

    // How many *physical* pixels per logical px we bake into the sprite
    double pixelRatio = 2.0, // 2x or 3x is ideal on modern phones
  }) async {
    final style = map.style;

    // Actual bitmap edge in physical pixels
    final int edge = (maxSize * pixelRatio).round();

    for (final e in images.entries) {
      final id = e.key.trim();
      final path = e.value.trim();
      if (id.isEmpty || path.isEmpty) continue;
      if (_loaded.contains(id)) continue;

      try {
        if (await style.hasStyleImage(id) == true) {
          _loaded.add(id);
          continue;
        }
      } catch (_) {}

      final mbx = await _loadAsMbxImage(
        id: id,
        path: path,
        edge: edge,
      );
      if (mbx == null) continue;

      try {
        await style.addStyleImage(
          id,
          pixelRatio, // ⬅️ tell Mapbox this is a 2x/3x sprite
          mbx,
          false,
          const <ImageStretches?>[],
          const <ImageStretches?>[],
          null,
        );
        _loaded.add(id);
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('MapLogoRegistry: add failed for $id -> $e2');
        }
      }
    }
  }


  void clear() => _loaded.clear();

  // ---------------------------------------------------------------------------
  // IMAGE PIPELINE
  //   raw path/gs/http  → bytes (disk cached when possible)
  //   bytes             → ui.Image
  //   ui.Image          → circular logo
  //   logo              → CircleAvatar (logo + colored ring)
  //   ui.Image          → PNG bytes → MbxImage
  // ---------------------------------------------------------------------------

  Future<MbxImage?> _loadAsMbxImage({
    required String id,
    required String path,
    required int edge,
  }) async {
    try {
      final bool isFriendAvatar = id.startsWith('friend_avatar_');
      final bool isOpenVariant = id.endsWith('_open'); // for venues

      // Inner circle for the logo itself – leave room for the border.
      int innerEdge = edge - (_borderWidth * 2).ceil();
      if (innerEdge < 8) innerEdge = edge; // safety

      // 1) Get base image: either friend placeholder / friend photo / venue logo
      late ui.Image img;

      if (isFriendAvatar && path == 'placeholder://friend') {
        // 👤 no photo → draw profile glyph as base
        img = await _drawFriendPlaceholder(edge: innerEdge);
      } else {
        final bytes = await _loadBytes(path);
        if (bytes == null || bytes.isEmpty) return null;
        img = await _decode(bytes);
      }

      // 2) Fit into circular inner logo
      final logoCircle = await _cropAndFitToCircle(
        img,
        edge: innerEdge,
        paddingFraction: 0.0,
      );

      // 3) Pick border color
      ui.Color borderColor;
      double borderWidth = _borderWidth;

      if (isFriendAvatar) {
        borderColor = _borderColorForFriend(id); // uses partyStatus from id
      } else {
        borderColor = isOpenVariant ? _borderOpenColor : _borderClosedColor;
      }

      // 4) Compose final avatar (black bg + colored ring + inner image)
      final avatar = await _composeCircleAvatar(
        logoCircle,
        edge: edge,
        borderWidth: borderWidth,
        borderColor: borderColor,
      );

      final pngData =
      await avatar.toByteData(format: ui.ImageByteFormat.png);
      if (pngData == null) return null;

      final pngBytes = pngData.buffer.asUint8List();

      return MbxImage(
        width: avatar.width,
        height: avatar.height,
        data: pngBytes,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MapLogoRegistry: _loadAsMbxImage failed for $path -> $e');
      }
      return null;
    }
  }


// _composeCircleAvatar stays exactly as you pasted,
// it already draws black fill + colored ring + image.




/// Load bytes for `path`:
  /// - normalize storage paths / gs:// → HTTPS when possible
  /// - use DefaultCacheManager for HTTP (disk cached)
  /// - fall back to Firebase Storage SDK otherwise
  Future<Uint8List?> _loadBytes(String path) async {
    final raw = path.trim();

    // Let your StorageUrl helper convert:
    //  - "venue_images/..."      → https://firebasestorage.googleapis.com/...
    //  - "gs://bucket/..."       → https://...
    //  - already-https           → same
    final normalized = StorageUrl.normalize(raw);
    final resolved = normalized.isNotEmpty ? normalized : raw;

    bool isHttp(String s) =>
        s.startsWith('http://') || s.startsWith('https://');

    // --- preferred path: HTTP + disk cache (cheapest on Firebase) -----
    if (isHttp(resolved)) {
      try {
        final file = await DefaultCacheManager()
            .getSingleFile(resolved, key: resolved);
        return await file.readAsBytes();
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              'MapLogoRegistry: HTTP cache fetch failed for $resolved -> $e');
        }
        // fall through to Firebase SDK as last resort
      }
    }

    // --- fallback: Firebase Storage SDK (no disk cache, but auth-safe) ----
    final storage = FirebaseStorage.instance;
    try {
      final ref = resolved.startsWith('gs://')
          ? storage.refFromURL(resolved)
          : storage.ref(resolved);
      return await ref.getData(8 * 1024 * 1024);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MapLogoRegistry: Firebase getData failed for $resolved -> $e');
      }
      return null;
    }
  }

  Future<ui.Image> _decode(Uint8List bytes) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, c.complete);
    return c.future;
  }

  // ---------------------------------------------------------------------------
  // circle fitting + optional transparent-padding crop
  // ---------------------------------------------------------------------------

  /// 1. Detect non-transparent bounding box.
  /// 2. Crop to that box.
  /// 3. Scale into a circle of diameter [edge] with some padding.
  Future<ui.Image> _cropAndFitToCircle(
      ui.Image src, {
        required int edge,
        double paddingFraction = 0.12,
      }) async {
    final width = src.width;
    final height = src.height;

    final byteData =
    await src.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      // fallback: simple scale into circle
      return _scaleImageToCircle(
        src,
        edge: edge,
        paddingFraction: paddingFraction,
      );
    }

    final bytes = byteData.buffer.asUint8List();

    const int alphaThreshold = 10;
    int left = width;
    int right = -1;
    int top = height;
    int bottom = -1;

    for (int y = 0; y < height; y++) {
      final rowOffset = y * width * 4;
      for (int x = 0; x < width; x++) {
        final offset = rowOffset + x * 4;
        final a = bytes[offset + 3];
        if (a > alphaThreshold) {
          if (x < left) left = x;
          if (x > right) right = x;
          if (y < top) top = y;
          if (y > bottom) bottom = y;
        }
      }
    }

    if (right < left || bottom < top) {
      // completely transparent → just scale
      return _scaleImageToCircle(
        src,
        edge: edge,
        paddingFraction: paddingFraction,
      );
    }

    const int paddingPx = 2;
    left = _clampInt(left - paddingPx, 0, width - 1);
    top = _clampInt(top - paddingPx, 0, height - 1);
    right = _clampInt(right + paddingPx, 0, width - 1);
    bottom = _clampInt(bottom + paddingPx, 0, height - 1);

    final cropWidth = right - left + 1;
    final cropHeight = bottom - top + 1;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()..isAntiAlias = true ..filterQuality = ui.FilterQuality.high;

    final radius = edge / 2.0;
    final center = ui.Offset(radius, radius);

    final circleRect =
    ui.Rect.fromCircle(center: center, radius: radius);
    final clipPath = ui.Path()..addOval(circleRect);
    canvas.clipPath(clipPath);

    final innerRadius = radius * (1.0 - paddingFraction);

    final srcRect = ui.Rect.fromLTWH(
      left.toDouble(),
      top.toDouble(),
      cropWidth.toDouble(),
      cropHeight.toDouble(),
    );

    final double scale =
        (innerRadius * 2.0) /
            (cropWidth > cropHeight ? cropWidth : cropHeight);

    final destW = cropWidth * scale;
    final destH = cropHeight * scale;

    final destRect = ui.Rect.fromLTWH(
      center.dx - destW / 2.0,
      center.dy - destH / 2.0,
      destW,
      destH,
    );

    canvas.drawImageRect(src, srcRect, destRect, paint);

    return await recorder.endRecording().toImage(edge, edge);
  }

  Future<ui.Image> _scaleImageToCircle(
      ui.Image src, {
        required int edge,
        double paddingFraction = 0.12,
      }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()..isAntiAlias = true ..filterQuality = ui.FilterQuality.high;

    final radius = edge / 2.0;
    final center = ui.Offset(radius, radius);
    final circleRect =
    ui.Rect.fromCircle(center: center, radius: radius);
    final clipPath = ui.Path()..addOval(circleRect);
    canvas.clipPath(clipPath);

    final innerRadius = radius * (1.0 - paddingFraction);

    final srcRect = ui.Rect.fromLTWH(
      0,
      0,
      src.width.toDouble(),
      src.height.toDouble(),
    );

    final double scale =
        (innerRadius * 2.0) /
            (src.width > src.height ? src.width : src.height);

    final destW = src.width * scale;
    final destH = src.height * scale;

    final destRect = ui.Rect.fromLTWH(
      center.dx - destW / 2.0,
      center.dy - destH / 2.0,
      destW,
      destH,
    );

    canvas.drawImageRect(src, srcRect, destRect, paint);

    return await recorder.endRecording().toImage(edge, edge);
  }

  /// Compose final CircleAvatar sprite:
  /// - `logoCircle` is already circular with transparent corners.
  /// - Draw it onto a bigger canvas and add a colored ring.
  Future<ui.Image> _composeCircleAvatar(
      ui.Image logoCircle, {
        required int edge,
        required double borderWidth,
        required ui.Color borderColor,
      }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final size = edge.toDouble();
    final center = ui.Offset(size / 2, size / 2);

    // 1) Fill inner circle with black
    final innerRadius = (size - borderWidth * 2) / 2.0;
    final bgPaint = ui.Paint()
      ..isAntiAlias = true
      ..style = ui.PaintingStyle.fill
      ..color = black;
    canvas.drawCircle(center, innerRadius, bgPaint);

    // 2) Draw logo inside
    final logoSize = size - borderWidth * 2;
    final srcRect = ui.Rect.fromLTWH(
      0,
      0,
      logoCircle.width.toDouble(),
      logoCircle.height.toDouble(),
    );
    final destRect = ui.Rect.fromLTWH(
      (size - logoSize) / 2,
      (size - logoSize) / 2,
      logoSize,
      logoSize,
    );

    final imgPaint = ui.Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.high;
    canvas.drawImageRect(logoCircle, srcRect, destRect, imgPaint);

    // 3) Optional border
    if (borderWidth > 0 && borderColor.alpha != 0) {
      final borderPaint = ui.Paint()
        ..isAntiAlias = true
        ..style = ui.PaintingStyle.stroke
        ..color = borderColor
        ..strokeWidth = borderWidth;

      canvas.drawCircle(center, size / 2 - borderWidth / 2, borderPaint);
    }

    return await recorder.endRecording().toImage(edge, edge);
  }

  int _clampInt(int v, int min, int max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }

  Future<ui.Image> _drawFriendPlaceholder({
    required int edge,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: String.fromCharCode(profileIcon.codePoint),
      style: TextStyle(
        fontFamily: profileIcon.fontFamily,
        package: profileIcon.fontPackage,
        fontSize: edge * 0.3,
        color: white,
      ),
    );

    textPainter.layout();
    final dx = (edge - textPainter.width) / 2.0;
    final dy = (edge - textPainter.height) / 2.0;
    textPainter.paint(canvas, Offset(dx, dy));

    final picture = recorder.endRecording();
    return picture.toImage(edge, edge);
  }


}

