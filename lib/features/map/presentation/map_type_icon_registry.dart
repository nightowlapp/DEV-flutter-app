// lib/features/map/presentation/map_type_icon_registry.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart'; // TextPainter, TextSpan, TextStyle
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';

class MapTypeIconRegistry {
  MapTypeIconRegistry._();
  static final MapTypeIconRegistry instance = MapTypeIconRegistry._();

  final _loaded = <String>{};

  /// Mapbox sprite ID -> IconData
  ///
  /// These IDs must match what you use in `icon-image`
  /// in MapStyle (wine_bar, bar, pub, etc).
  static final Map<String, IconData> _iconById = {
    'wine_bar': wineBarIcon,
    'cocktail_bar': cocktailBarIcon,
    'beer_bar': beerBarIcon,
    'karaoke_bar': karaokeBarIcon,
    'sports_bar': sportsBarIcon,
    'gay_bar': gayBarIcon,
    'pub': pubIcon,
    'bar': barIcon,
    'club': clubIcon,
    'unknown': unknowBarIcon,
  };

  Future<void> ensureTypeIcons({
    required MapboxMap map,
    double logicalSize = 24.0,
    double pixelRatio = 2.0,
  }) async {
    final style = map.style;
    final int edge = (logicalSize * pixelRatio).round();

    Future<void> _ensureVariant({
      required String id,
      required IconData iconData,
      required ui.Color color,
    }) async {
      if (_loaded.contains(id)) return;

      try {
        if (await style.hasStyleImage(id) == true) {
          _loaded.add(id);
          return;
        }
      } catch (_) {
        // ignore
      }

      final img = await _drawIcon(
        iconData,
        edge: edge,
        color: color,
      );

      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      final mbxImage = MbxImage(
        width: img.width,
        height: img.height,
        data: pngBytes,
      );

      try {
        await style.addStyleImage(
          id,
          pixelRatio,
          mbxImage,
          false, // sdf = false, normal PNG
          const <ImageStretches?>[],
          const <ImageStretches?>[],
          null,
        );
        _loaded.add(id);
      } catch (_) {
        // ignore or log
      }
    }

    for (final entry in _iconById.entries) {
      final baseId = entry.key;
      final iconData = entry.value;

      // white base (still available if you need it anywhere)
      await _ensureVariant(
        id: baseId,
        iconData: iconData,
        color: const ui.Color(0xFFFFFFFF),
      );

      //TODO purple if open/close soon

      // green = open
      await _ensureVariant(
        id: '${baseId}_open',
        iconData: iconData,
        color: green, // from your colors.dart
      );

      // red = closed
      await _ensureVariant(
        id: '${baseId}_closed',
        iconData: iconData,
        color: red, // from your colors.dart
      );
    }
  }

  Future<ui.Image> _drawIcon(
      IconData icon, {
        required int edge,
        required ui.Color color,
      }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Transparent background by default – no fill.

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontSize: edge * 0.7, // a bit smaller than full canvas
        color: color,
      ),
    );

    textPainter.layout();

    final dx = (edge - textPainter.width) / 2.0;
    final dy = (edge - textPainter.height) / 2.0;
    textPainter.paint(canvas, Offset(dx, dy));

    final picture = recorder.endRecording();
    return picture.toImage(edge, edge);
  }

  void clear() => _loaded.clear();
}
