// lib/features/explore/ranking/explore_ranked_providers.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/utility/distance.dart';

import '../../../core/storage/venues_sso.dart';
import '../../../data/providers/users/user_providers.dart';
import '../../../data/providers/venues/venue_providers.dart';
import '../../../data/services/location/location_providers.dart';
import '../filters/filter_controller.dart';
import '../filters/filter_predicate.dart';
import '../search/search_controller.dart';
import '../search/search_engine.dart';
import 'venue_ranker.dart';

/// Rules for ranking (we can later make this react to search, etc.)
final rankerRulesProvider = StateProvider<PointRules>((_) => const PointRules());

final _rankerAvProvider = Provider<AsyncValue<VenueRanker>>((ref) {
  final rules = ref.watch(rankerRulesProvider);

  // IMPORTANT: mePrefsAvProvider must yield AsyncValue<UserPrefs>
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
    return await stream
        .firstWhere((p) => p != null)
        .timeout(const Duration(seconds: 2));
  } on TimeoutException {
    return null;
  }
});

/// Base ranked list (no text search / filters yet).
final exploreRankedVenuesProvider = Provider<AsyncValue<List<Venue>>>((ref) {
  final bootDone = ref.watch(venuesLocalBootDoneProvider);
  final all = bootDone ? ref.watch(allVenuesListProvider) : const <Venue>[];

  final rankerAv = ref.watch(_rankerAvProvider);

  // // 👇 DEBUG: log prefs whenever ranker is ready (debug builds only)
  // assert(() {
  //   rankerAv.whenData((ranker) {
  //     debugPrint(
  //       'RANKER PREFS -> '
  //           'types=${ranker.prefs?.preferredVenueTypes} '
  //           'maxKm=${ranker.prefs?.maxDistanceKm} '
  //           'age=${ranker.prefs?.age} '
  //           'status=${ranker.prefs?.partyStatus} '
  //           'gender=${ranker.prefs?.gender}',
  //     );
  //   });
  //   return true;
  // }());

  if (rankerAv.isLoading) return AsyncData(all.take(24).toList());
  if (rankerAv.hasError) {
    return AsyncError(rankerAv.error!, rankerAv.stackTrace!);
  }
  final ranker = rankerAv.requireValue;

  final firstFixAv = ref.watch(firstFixOrNullProvider);
  final userLoc = firstFixAv.maybeWhen(data: (v) => v, orElse: () => null);

  final prefsAv = ref.watch(mePrefsAvProvider);
  if (prefsAv.isLoading) {
    final warm =
    ranker.sort(all.take(24).toList(), userLocation: userLoc, media: null);
    return AsyncData(warm);
  }
  if (prefsAv.hasError) {
    return AsyncError(prefsAv.error!, prefsAv.stackTrace!);
  }
  final prefs = prefsAv.requireValue;

  const firstKm = 5.0;
  final gateKm = prefs.maxDistanceKm > 0
      ? (prefs.maxDistanceKm < firstKm ? prefs.maxDistanceKm : firstKm)
      : firstKm;
  final gateMeters = gateKm * 1000.0;

  final Iterable<Venue> pool = (userLoc == null)
      ? all
      : all.where(
        (v) => Distance.metersLatLng(userLoc, v.entry) <= gateMeters,
  );

  final ranked =
  ranker.sort(pool.toList(), userLocation: userLoc, media: null);
  return AsyncData(ranked);
});

/// What the Explore grid should actually show:
/// 1. Rank venues
/// 2. Apply text search
/// 3. Apply filters **only when not searching**
final exploreVisibleVenuesProvider =
Provider.autoDispose<AsyncValue<List<Venue>>>((ref) {
  final rankedAv = ref.watch(exploreRankedVenuesProvider);

  final q = ref.watch(searchQueryProvider);
  final filters = ref.watch(filtersProvider);
  final engine = ref.watch(venueSearchEngineProvider);
  final userLoc = ref
      .watch(latLngSafeStreamProvider)
      .maybeWhen(data: (p) => p, orElse: () => null);

  return rankedAv.when(
    data: (ranked) {
      var xs = ranked;

      final query = q.trim();
      final isSearching = query.isNotEmpty;

      // 2) Text search (always against ranked list)
      if (isSearching) {
        xs = engine.filter(xs, query, userLoc: userLoc);
      }

      // 3) Filters only when NOT searching
      if (!isSearching) {
        xs = xs
            .where((v) => venuePassesFilters(v, filters, userLoc: userLoc))
            .toList(growable: false);
      }

      return AsyncData(xs);
    },
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
  );
}, name: 'exploreVisibleVenuesProvider');
