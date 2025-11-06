// lib/features/explore/presentation/explore_ranked_providers.dart
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

/// Emits only once everything needed for a *stable* ranked list is ready:
/// - local boot done
/// - user prefs loaded
/// - ranker built
/// - first non-null user location received (prevents the “pre-location” flash)
final exploreRankedVenuesProvider = Provider<AsyncValue<List<Venue>>>((ref) {
  // 1) Wait local cache boot
  final bootDone = ref.watch(venuesLocalBootDoneProvider);
  if (!bootDone) return const AsyncLoading();

  // 2) Ranker ready (depends on prefs)
  final rankerAv = ref.watch(_rankerAvProvider);
  if (rankerAv.isLoading) return const AsyncLoading();
  if (rankerAv.hasError)  return AsyncError(rankerAv.error!, rankerAv.stackTrace!);
  final ranker = rankerAv.requireValue;

  // 3) Require a *first* location value to avoid the early, ungated paint
  final userLocAv = ref.watch(latLngSafeStreamProvider);
  if (userLocAv.isLoading) return const AsyncLoading();
  if (userLocAv.hasError)  return AsyncError(userLocAv.error!, userLocAv.stackTrace!);
  final userLoc = userLocAv.value;
  if (userLoc == null) {
    // Keep loading until we actually have a location
    return const AsyncLoading();
  }

  // 4) Inputs
  final all   = ref.watch(allVenuesListProvider);
  final prefsAv = ref.watch(mePrefsAvProvider);
  if (prefsAv.isLoading) return const AsyncLoading();
  if (prefsAv.hasError)  return AsyncError(prefsAv.error!, prefsAv.stackTrace!);
  final prefs = prefsAv.requireValue;

  // Gate first render to min(5km, user.maxDistanceKm)
  const firstKm = 5.0;
  final gateKm  = prefs.maxDistanceKm > 0
      ? (prefs.maxDistanceKm < firstKm ? prefs.maxDistanceKm : firstKm)
      : firstKm;
  final gateMeters = gateKm * 1000.0;

  final filtered = all.where(
        (v) => Distance.metersLatLng(userLoc, v.entry) <= gateMeters,
  ).toList();

  final ranked = ranker.sort(filtered, userLocation: userLoc, media: null);
  return AsyncData(ranked);
});
