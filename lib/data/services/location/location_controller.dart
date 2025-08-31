// lib/features/location/location_controller.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

import 'location_status.dart';

class LocationController extends StateNotifier<LocationStatus> {
  LocationController() : super(const LocationStatus.initial()) {
    _init();
  }

  StreamSubscription<ServiceStatus>? _serviceSub;
  Timer? _poll;

  Future<void> _init() async {
    await refresh();
    // GPS service toggle listener
    _serviceSub = Geolocator.getServiceStatusStream().listen((_) => refresh());
    _ensurePolling();
  }

  Future<void> refresh() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    final perm = await Geolocator.checkPermission();
    state = state.copyWith(servicesEnabled: enabled, permission: perm);
    _ensurePolling();
  }

  void _ensurePolling() {
    _poll?.cancel();
    if (!state.ready) {
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => refresh());
    }
  }

  Future<void> requestPermission() async {
    var p = await Geolocator.checkPermission();

    if (p == LocationPermission.denied ||
        p == LocationPermission.unableToDetermine) {
      p = await Geolocator.requestPermission(); // shows the OS sheet
    } else if (p == LocationPermission.deniedForever) {
      // "Don't ask again" → go to the app's permission screen.
      await AppPermissionNavigator.openAppLocationPermission();
    }
    await refresh();
  }

  Future<void> openAppPermissions() async {
    await AppPermissionNavigator.openAppLocationPermission(); // app -> permissions
    await refresh();
  }

  Future<void> openLocationServices() async {
    await Geolocator.openLocationSettings(); // global Location toggle
    await refresh();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
    await refresh();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
    await refresh();
  }

  Future<LatLng?> currentLatLngOrNull() async {
    if (!state.ready) return null;
    try {
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  Stream<LatLng>? latLngStream({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilterMeters = 5,
  }) {
    if (!state.ready) return null;
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
      ),
    ).map((p) => LatLng(p.latitude, p.longitude));
  }

  @override
  void dispose() {
    _serviceSub?.cancel();
    _poll?.cancel();
    super.dispose();
  }
}

final locationControllerProvider =
StateNotifierProvider<LocationController, LocationStatus>(
      (ref) {
    final c = LocationController();
    ref.onDispose(c.dispose);
    return c;
  },
);

final currentLatLngProvider = FutureProvider<LatLng?>((ref) async {
  final status = ref.watch(locationControllerProvider);
  if (!status.ready) return null;
  return ref.read(locationControllerProvider.notifier).currentLatLngOrNull();
});


class AppPermissionNavigator {
  static const _ch = MethodChannel('nightowl/permissions');

  /// Android: tries to open the app's Location permission screen (API 30+),
  /// falls back to App details if unavailable.
  /// iOS: opens the app's Settings page.
  static Future<bool> openAppLocationPermission() async {
    try {
      final ok = await _ch.invokeMethod<bool>('openAppLocationPermission');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}
