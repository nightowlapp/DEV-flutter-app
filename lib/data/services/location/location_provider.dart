// lib/features/location/location_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

import 'location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  final svc = LocationService();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Ensure location ready (use when you want to block on perms)
final locationReadyProvider = FutureProvider<void>((ref) async {
  await ref.watch(locationServiceProvider).initialize();
});

/// One-shot user location (null if unavailable)
final currentLatLngProvider = FutureProvider<LatLng?>((ref) async {
  try {
    // Don’t hard-block UI; try to be helpful.
    await ref.watch(locationServiceProvider).initialize();
  } catch (_) {
    // ignore – returns null
  }
  return ref.watch(locationServiceProvider).currentLatLngOrNull();
});

/// Continuous updates (opt-in UI)
final latLngStreamProvider = StreamProvider<LatLng>((ref) {
  // No initialize() here to keep it non-throwing; handle at caller if needed.
  return ref.watch(locationServiceProvider).latLngStream();
});
