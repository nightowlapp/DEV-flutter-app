// lib/features/location/location_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

class LocationService {
  factory LocationService() => _instance;
  LocationService._internal();
  static final LocationService _instance = LocationService._internal();

  Future<void> initialize() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw Exception('Location services are disabled.');

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }
  }

  /// Best-effort: last known if available, else current (with short timeout).
  Future<LatLng?> lastKnownOrCurrent({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return LatLng(last.latitude, last.longitude);

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(timeout, onTimeout: () {
            return Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
            );
          }
        );

      return LatLng(pos.latitude, pos.longitude);
    }
    catch (_) {
      return null;
    }
  }

  Future<LatLng?> currentLatLngOrNull() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(p.latitude, p.longitude);
    }
    catch (_) {
      return null;
    }
  }

  Stream<LatLng> latLngStream({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilterMeters = 5,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
      ),
    ).map((p) => LatLng(p.latitude, p.longitude));
  }

  void dispose() {/* no-op */}
  // TODO below
  // Future<void> pushLastKnownToFirestore(WidgetRef ref) async {
  //   final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
  //   if (uid == null) return;
  //   final ll = await ref.read(locationServiceProvider).lastKnownOrCurrent();
  //   if (ll == null) return;
  //   await ref.read(personalSettingsRepositoryProvider).setLastKnownLocation(
  //     uid: uid,
  //     lat: ll.lat,
  //     lon: ll.lng,
  //   );
  // }
}
