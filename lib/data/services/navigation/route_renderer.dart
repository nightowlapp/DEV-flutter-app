// lib/features/navigation/services/route_renderer.dart
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import '../../../models/navigation/nav_models.dart';
import '../../../shared/utility/distance.dart';

extension _MbPos on LatLng {
  mb.Position toMb() => mb.Position(lng, lat); // (lon, lat)
}

enum RouteStyle { line, dots }

class RouteRenderer {
  final mb.MapboxMap map;

  late final mb.PolylineAnnotationManager _lineMgr;
  late final mb.CircleAnnotationManager _dotMgr;

  mb.PolylineAnnotation? _line;
  final List<mb.CircleAnnotation> _dots = [];

  RouteRenderer._(this.map);

  static Future<RouteRenderer> attach(mb.MapboxMap map) async {
    final r = RouteRenderer._(map);
    r._lineMgr = await map.annotations.createPolylineAnnotationManager();
    r._dotMgr  = await map.annotations.createCircleAnnotationManager();
    return r;
  }

  int _argb(Color c) => c.value; // 0xAARRGGBB

  Future<void> show(
      NavRoute route, {
        RouteStyle style = RouteStyle.line,
        Color color = const Color(0xFF2563EB),
        double width = 6,
        double opacity = .9,
        // dots
        double dotRadius = 3.5,
        double dotOpacity = .95,
        int dotStep = 4,
      }) async {
    await clear();
    if (route.points.isEmpty) return;

    if (style == RouteStyle.line) {
      _line = await _lineMgr.create(mb.PolylineAnnotationOptions(
        geometry: mb.LineString(
          coordinates: route.points.map((p) => p.toMb()).toList(),
        ),
        lineColor: _argb(color), // int, not string
        lineWidth: width,
        lineOpacity: opacity,
      ));
    } else {
      // Render dots along the path
      final opts = <mb.CircleAnnotationOptions>[];
      for (int i = 0; i < route.points.length; i += dotStep) {
        final p = route.points[i];
        opts.add(mb.CircleAnnotationOptions(
          geometry: mb.Point(coordinates: p.toMb()),
          circleRadius: dotRadius,
          circleColor: _argb(color), // int
          circleOpacity: dotOpacity,
        ));
      }
      if (opts.isNotEmpty) {
        final created = await _dotMgr.createMulti(opts); // List<CircleAnnotation?>
        // Filter out any nulls to satisfy List<CircleAnnotation>
        for (final a in created) {
          if (a != null) _dots.add(a);
        }
      }
    }
  }

  Future<void> clear() async {
    if (_line != null) {
      await _lineMgr.delete(_line!);
      _line = null;
    }
    if (_dots.isNotEmpty) {
      // Your SDK doesn’t expose deleteMulti for circles → nuke manager’s circles.
      await _dotMgr.deleteAll();
      _dots.clear();
      // If your SDK also lacked deleteAll, fallback:
      // for (final a in List<mb.CircleAnnotation>.from(_dots)) {
      //   try { await _dotMgr.delete(a); } catch (_) {}
      // }
      // _dots.clear();
    }
  }

  Future<void> fitToRoute(
      NavRoute route, {
        double padding = 48,
        int durationMs = 800,
      }) async {
    if (route.points.isEmpty) return;
    final b = Bounds.fromPoints(route.points);
    await map.flyTo(
      mb.CameraOptions(
        center: mb.Point(coordinates: mb.Position(b.center.lng, b.center.lat)),
        zoom: 12,
      ),
      mb.MapAnimationOptions(duration: durationMs),
    );
  }
}
