// lib/features/explore/search/search_match_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/explore/search/search_engine.dart';
import 'package:nightowlcode/models/venues/venue.dart';

import '../../../data/services/location/location_providers.dart';
import '../filters/filter_controller.dart'; // 👈 NEW
import '../filters/filter_predicate.dart'; // 👈 NEW
import '../ranking/explore_ranked_providers.dart';
import 'search_controller.dart';

/// How many venues match the current **search text** (ignoring filters).
final searchMatchCountProvider = Provider.autoDispose<int?>((ref) {
  // Ranked venues list (no search / filters applied yet)
  final rankedAv = ref.watch(exploreRankedVenuesProvider);
  final List<Venue>? ranked = rankedAv.asData?.value;
  if (ranked == null) return null;

  final q = ref.watch(searchQueryProvider).trim();
  if (q.isEmpty) return null;

  final engine = ref.watch(venueSearchEngineProvider);
  final userLoc = ref
      .watch(latLngSafeStreamProvider)
      .maybeWhen(data: (p) => p, orElse: () => null);

  // IMPORTANT: no filters here → pure "how many venues match this query?"
  final xs = engine.filter(ranked, q, userLoc: userLoc);
  return xs.length;
}, name: 'searchMatchCountProvider');

/// How many venues match the current **filters** (when no search text).
final filterMatchCountProvider = Provider.autoDispose<int?>((ref) {
  // Ranked venues list (no search / filters applied yet)
  final rankedAv = ref.watch(exploreRankedVenuesProvider);
  final List<Venue>? ranked = rankedAv.asData?.value;
  if (ranked == null) return null;

  final filters = ref.watch(filtersProvider);
  final userLoc = ref
      .watch(latLngSafeStreamProvider)
      .maybeWhen(data: (p) => p, orElse: () => null);

  int count = 0;
  for (final v in ranked) {
    if (venuePassesFilters(v, filters, userLoc: userLoc)) {
      count++;
    }
  }
  return count;
}, name: 'filterMatchCountProvider');
