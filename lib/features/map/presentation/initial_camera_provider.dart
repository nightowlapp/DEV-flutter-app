// lib/features/map/presentation/initial_camera_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

/// Copenhagen as a hard fallback.
const _fallbackLatLng = LatLng(55.6761, 12.5683); // (lat, lng)

CameraOptions get fallbackCamera => CameraOptions(
  // Mapbox Position is (lng, lat)
  center: Point(coordinates: Position(_fallbackLatLng.lng, _fallbackLatLng.lat)),
  zoom: mapZoomDefault,
);

final initialCameraProvider = FutureProvider<CameraOptions>((ref) async {
  // 1) Ensure location permission (don’t block forever).
  var perm = await geo.Geolocator.checkPermission();
  if (perm == geo.LocationPermission.denied) {
    perm = await geo.Geolocator.requestPermission();
  }
  final servicesOn = await geo.Geolocator.isLocationServiceEnabled();

  // 2) Try current position (fast timeout to avoid hanging on cold start).
  geo.Position? pos;
  if (servicesOn && perm != geo.LocationPermission.deniedForever) {
    try {
      pos = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 2));
    } catch (_) {
      // ignore; we’ll fall back to last known
    }
  }

  // 3) Fall back to last-known if current wasn’t available.
  pos ??= await geo.Geolocator.getLastKnownPosition();

  // 4) Final fallback to a static center.
  final target = (pos != null)
      ? LatLng(pos.latitude, pos.longitude)
      : _fallbackLatLng;

  return CameraOptions(
    center: Point(coordinates: Position(target.lng, target.lat)),
    zoom: mapZoomDefault,
    pitch: 0,
    bearing: 0,
  );
});
