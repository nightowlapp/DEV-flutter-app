// lib/features/navigation/services/route_renderer.dart
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import '../../../models/navigation/nav_models.dart';
import '../../../shared/utility/distance.dart';

extension _MbPos on LatLng {
  mb.Position toMb() => mb.Position(lng, lat); // (lon, lat)
}

class RouteRenderer {
  final mb.MapboxMap map;
  late final mb.PolylineAnnotationManager _mgr;
  mb.PolylineAnnotation? _anno;

  RouteRenderer._(this.map);

  static Future<RouteRenderer> attach(mb.MapboxMap map) async {
    final r = RouteRenderer._(map);
    r._mgr = await map.annotations.createPolylineAnnotationManager();
    return r;
  }

  Future<void> show(
      NavRoute route, {
        Color color = const Color(0xFF2563EB),
        double width = 6,
        double opacity = .9,
      }) async {
    if (_anno != null) {
      await _mgr.delete(_anno!);
      _anno = null;
    }
    if (route.points.isEmpty) return;

    _anno = await _mgr.create(mb.PolylineAnnotationOptions(
      geometry: mb.LineString(coordinates: route.points.map((p) => p.toMb()).toList()),
      lineColor: white.toARGB32(),         // ✅ hex string
      lineWidth: width,
      lineOpacity: opacity,
    ));
  }

  Future<void> clear() async {
    if (_anno != null) {
      await _mgr.delete(_anno!);
      _anno = null;
    }
  }

  Future<void> fitToRoute(NavRoute route, {double padding = 48, int durationMs = 800}) async {
    if (route.points.isEmpty) return;

    // Prefer SDK helper when available
    // try {
    //   final cam = await map.cameraForCoordinates(
    //     route.points.map((p) => p.toMb()).toList(), //TODO Type mismatch
    //     mb.MbxEdgeInsets(top: padding,left:  padding,bottom:  padding,right:  padding),
    //     null,
    //     null,
    //   );
    //   await map.easeTo(cam, mb.MapAnimationOptions(duration: durationMs));
    //   return;
    // } catch (_)
    {
      // Fallback to simple bounds
      final b = Bounds.fromPoints(route.points);
      await map.flyTo(
        mb.CameraOptions(center: mb.Point(coordinates: mb.Position(b.center.lng, b.center.lat)), zoom: 12),
        mb.MapAnimationOptions(duration: durationMs),
      );
    }
  }
}
