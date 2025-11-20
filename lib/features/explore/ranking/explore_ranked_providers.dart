import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/utility/distance.dart';
import '../../../core/storage/venues_sso.dart';
import '../../../data/providers/users/user_providers.dart';
import '../../../data/providers/venues/venue_providers.dart';
import '../../../data/services/location/location_providers.dart';
import 'venue_ranker.dart';

final rankerRulesProvider = StateProvider<PointRules>((_) => const PointRules());

final _rankerAvProvider = Provider<AsyncValue<VenueRanker>>((ref) {
  final rules = ref.watch(rankerRulesProvider);
  final prefsAv = ref.watch(mePrefsAvProvider);
  return prefsAv.when(
    data: (prefs) => AsyncData(VenueRanker(rules: rules, prefs: prefs)),
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
  );
});

/// First non-null location in ≤2s, else null.
final firstFixOrNullProvider = FutureProvider<dynamic>((ref) async {
  final stream = ref.watch(latLngSafeStreamProvider.stream);
  try {
    return await stream.firstWhere((p) => p != null).timeout(const Duration(seconds: 2));
  } on TimeoutException {
    return null;
  }
});

/// Prefs with timeout → fall back to a minimal “defaults” object so we never block.
/// Replace `PointRules()`/prefs default with whatever makes sense in your app.
final exploreRankedVenuesProvider = Provider<AsyncValue<List<Venue>>>((ref) {
  final bootDone = ref.watch(venuesLocalBootDoneProvider);
  final all = bootDone ? ref.watch(allVenuesListProvider) : const <Venue>[];

  final rankerAv = ref.watch(_rankerAvProvider);
  if (rankerAv.isLoading) return AsyncData(all.take(24).toList());
  if (rankerAv.hasError)  return AsyncError(rankerAv.error!, rankerAv.stackTrace!);
  final ranker = rankerAv.requireValue;

  final firstFixAv = ref.watch(firstFixOrNullProvider);
  final userLoc = firstFixAv.maybeWhen(data: (v) => v, orElse: () => null);

  final prefsAv = ref.watch(mePrefsAvProvider);
  if (prefsAv.isLoading) {
    final warm = ranker.sort(all.take(24).toList(), userLocation: userLoc, media: null);
    return AsyncData(warm);
  }
  if (prefsAv.hasError) return AsyncError(prefsAv.error!, prefsAv.stackTrace!);
  final prefs = prefsAv.requireValue;

  const firstKm = 5.0;
  final gateKm = prefs.maxDistanceKm > 0
      ? (prefs.maxDistanceKm < firstKm ? prefs.maxDistanceKm : firstKm)
      : firstKm;
  final gateMeters = gateKm * 1000.0;

  final Iterable<Venue> pool = (userLoc == null)
      ? all
      : all.where((v) => Distance.metersLatLng(userLoc, v.entry) <= gateMeters);

  final ranked = ranker.sort(pool.toList(), userLocation: userLoc, media: null);
  return AsyncData(ranked);
});
