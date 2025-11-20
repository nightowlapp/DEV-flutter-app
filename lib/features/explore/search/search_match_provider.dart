// lib/features/explore/search/search_match_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/explore/search/search_engine.dart';
import 'package:nightowlcode/models/venues/venue.dart';

import '../../../data/services/location/location_providers.dart';
import '../filters/filter_controller.dart';
import '../filters/filter_predicate.dart';
import '../ranking/explore_ranked_providers.dart';
import 'search_controller.dart';

final searchMatchCountProvider = Provider.autoDispose<int?>((ref) {
  // Ranked venues list (no search applied yet)
  final rankedAv = ref.watch(exploreRankedVenuesProvider);
  final List<Venue>? ranked = rankedAv.asData?.value;
  if (ranked == null) return null;

  // Only show matches counter when user is actually typing
  final q = ref.watch(searchQueryProvider).trim();
  if (q.isEmpty) return null;

  // Search + basic filters
  final engine = ref.watch(venueSearchEngineProvider);
  final filters = ref.watch(filtersProvider);
  final userLoc = ref
      .watch(latLngSafeStreamProvider)
      .maybeWhen(data: (p) => p, orElse: () => null);

  var xs = engine.filter(ranked, q, userLoc: userLoc);
  xs = xs
      .where((v) => venuePassesFilters(v, filters, userLoc: userLoc))
      .toList(growable: false);

  return xs.length;
}, name: 'searchMatchCountProvider');
