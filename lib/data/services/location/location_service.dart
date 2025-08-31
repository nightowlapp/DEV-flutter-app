// lib/features/location/location_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

class LocationService {
  factory LocationService() => _instance;
  LocationService._internal();
  static final LocationService _instance = LocationService._internal();

  StreamSubscription<Position>? _positionSub;

  /// Ensure location services/permission are available or throw.
  Future<void> initialize() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Location services are disabled.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      throw Exception('Location permission denied.');
    }
    if (perm == LocationPermission.deniedForever) {
    perm = await Geolocator.requestPermission();
      throw Exception('Location permission permanently denied.');
    }
  }



  /// One-shot current position (null if not available).
  Future<LatLng?> currentLatLngOrNull() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Stream of LatLng updates.
  Stream<LatLng> latLngStream({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilterMeters = 5,
  }) {
    _positionSub?.cancel(); // ensure single active stream on service
    final stream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
      ),
    );
    // caller owns the subscription; we return mapped stream
    return stream.map((p) => LatLng(p.latitude, p.longitude));
  }

  void dispose() {
    _positionSub?.cancel();
    _positionSub = null;
  }
}
