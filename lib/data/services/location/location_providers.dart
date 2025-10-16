// lib/features/location/location_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import '../../../shared/utility/distance.dart';
import 'location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  final svc = LocationService();
  ref.onDispose(svc.dispose);
  return svc;
});

final locationReadyProvider = FutureProvider<void>((ref) async {
  await ref.watch(locationServiceProvider).initialize();
});

final currentLatLngProvider = FutureProvider<LatLng?>((ref) async {
  try {
    await ref.watch(locationServiceProvider).initialize();
  } catch (_) {}
  // prefer lastKnownOrCurrent so it can be instant
  return ref.watch(locationServiceProvider).lastKnownOrCurrent();
});

/// Raw stream
final latLngStreamProvider = StreamProvider<LatLng>((ref) {
  return ref.watch(locationServiceProvider).latLngStream();
});

/// Safe stream for background logic
final latLngSafeStreamProvider = StreamProvider<LatLng>((ref) async* {
  final svc = ref.watch(locationServiceProvider);
  try {
    await svc.initialize();
  } catch (_) {
    yield* const Stream<LatLng>.empty();
    return;
  }

  yield* svc
      .latLngStream(distanceFilterMeters: 5)
      .distinct((a, b) => Distance.meters(a.lat, a.lng, b.lat, b.lng) < 1.5)
      .handleError((_) {});
});
