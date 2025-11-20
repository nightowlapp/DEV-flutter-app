// lib/features/explore/search/search_match_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/explore/search/search_engine.dart';
import 'package:nightowlcode/models/venues/venue.dart';

import '../../../data/services/location/location_providers.dart';
import '../ranking/explore_ranked_providers.dart';
import 'search_controller.dart';

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
