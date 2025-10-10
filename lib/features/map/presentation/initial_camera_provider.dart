// lib/features/map/presentation/initial_camera_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nightowlcode/data/services/location/location_controller.dart';
import 'package:nightowlcode/shared/constants/values.dart';

final _fallback = CameraOptions(
  //TODO make users location.
  center: Point(coordinates: Position(12.5683, 55.6761)), // Copenhagen
  zoom: mapZoomDefault,
);

final initialCameraProvider = FutureProvider<CameraOptions>((ref) async {
  final loc =
      await ref.read(locationControllerProvider.notifier).currentLatLngOrNull();
  if (loc == null) return _fallback;
  return CameraOptions(
      center: Point(coordinates: Position(loc.lng, loc.lat)),
      zoom: mapZoomDefault);
});

CameraOptions get fallbackCamera => _fallback;
