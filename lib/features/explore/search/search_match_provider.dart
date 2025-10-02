// lib/features/explore/search/search_match_count_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/explore/search/search_engine.dart';
import 'package:nightowlcode/models/venues/venue.dart';

import '../../../data/providers/other_providers.dart';
import '../presentation/ranked_venues_controller.dart';
import 'search_controller.dart';

/// Returns `null` when no active search (so the UI can show "nearby" instead).
final searchMatchCountProvider = Provider.autoDispose<int?>((ref) {
  final ranked = ref.watch(rankedVenuesProvider).asData?.value;
  if (ranked == null) return null;

  final q = ref.watch(searchQueryProvider);
  if (q.isEmpty) return null;

  final engine = ref.watch(venueSearchEngineProvider);
  final List<Venue> matches = engine.filter(ranked.venues, q);
  return matches.length;
});
