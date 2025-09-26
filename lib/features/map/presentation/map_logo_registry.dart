// lib/features/map/presentation/map_logo_registry.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapLogoRegistry {
  MapLogoRegistry._();
  static final MapLogoRegistry instance = MapLogoRegistry._();

  final _loaded = <String>{};

  Future<void> syncIdToUrl({   // keep the name if you like; it’s really ID->path
    required MapboxMap map,
    required Map<String, String> images, // id -> "venue_images/<id>/logo.webp" | gs://... | https://...
    int maxSize = 96,
  }) async {
    final style = map.style;

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

      final mbx = await _loadAsMbxImage(path, maxEdge: maxSize);
      if (mbx == null) continue;

      try {
        await style.addStyleImage(
          id, 1.0, mbx, false,
          const <ImageStretches?>[], const <ImageStretches?>[], null,
        );
        _loaded.add(id);
      } catch (_) {
        try {
          await style.removeStyleImage(id);
          await style.addStyleImage(
            id, 1.0, mbx, false,
            const <ImageStretches?>[], const <ImageStretches?>[], null,
          );
          _loaded.add(id);
        } catch (e2) {
          if (kDebugMode) debugPrint('MapLogoRegistry: add failed for $id -> $e2');
        }
      }
    }
  }

  void clear() => _loaded.clear();

  // -------- internals --------

  Future<MbxImage?> _loadAsMbxImage(String path, {int maxEdge = 96}) async {
    try {
      final bytes = await _loadBytes(path);
      if (bytes == null || bytes.isEmpty) return null;

      final decoded = await _decode(bytes);
      final scale = _scaleToFit(decoded.width, decoded.height, maxEdge);
      final w = (decoded.width * scale).round().clamp(1, 2048);
      final h = (decoded.height * scale).round().clamp(1, 2048);

      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec);
      final paint = ui.Paint()..isAntiAlias = true;
      canvas.drawImageRect(
        decoded,
        ui.Rect.fromLTWH(0, 0, decoded.width.toDouble(), decoded.height.toDouble()),
        ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        paint,
      );

      final resized = await rec.endRecording().toImage(w, h);
      final data = await resized.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return null;

      return MbxImage(width: w, height: h, data: data.buffer.asUint8List());
    } catch (e) {
      if (kDebugMode) debugPrint('MapLogoRegistry: loadAsMbxImage failed for $path -> $e');
      return null;
    }
  }

  Future<Uint8List?> _loadBytes(String path) async {
    // Detect Firebase Storage HTTPS and use SDK (so auth works)
    bool _isFirebaseStorageHttps(String url) {
      try {
        final u = Uri.parse(url);
        if (u.scheme != 'http' && u.scheme != 'https') return false;
        // covers both firebasestorage.googleapis.com and storage.googleapis.com domains
        final h = u.host.toLowerCase();
        return h.contains('firebasestorage.googleapis.com') ||
            h.contains('storage.googleapis.com');
      } catch (_) {
        return false;
      }
    }

    final storage = FirebaseStorage.instance;

    // Use Firebase SDK for anything we can resolve as a Firebase ref
    if (path.startsWith('gs://') || _isFirebaseStorageHttps(path) || !path.startsWith('http')) {
      try {
        final ref = path.startsWith('gs://')
            ? storage.refFromURL(path)
            : (path.startsWith('http')
            ? storage.refFromURL(path) // https -> refFromURL keeps auth
            : storage.ref(path));      // bucket relative path
        return await ref.getData(8 * 1024 * 1024);
      } catch (e) {
        if (kDebugMode) debugPrint('MapLogoRegistry: Firebase getData failed for $path -> $e');
        return null;
      }
    }

    // Fallback: regular web URL (non-Firebase) via cache manager
    try {
      final f = await DefaultCacheManager().getSingleFile(path);
      return f.readAsBytes();
    } catch (e) {
      if (kDebugMode) debugPrint('MapLogoRegistry: HTTP fetch failed for $path -> $e');
      return null;
    }
  }

  Future<ui.Image> _decode(Uint8List bytes) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, c.complete);
    return c.future;
  }

  double _scaleToFit(int w, int h, int maxEdge) {
    final maxDim = w > h ? w : h;
    return maxDim <= maxEdge ? 1.0 : maxEdge / maxDim;
  }
}
