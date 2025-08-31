// lib/features/explore/search/search_match_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import '../presentation/ranked_venues_controller.dart';
import '../search/search_controller.dart';
import '../search/search_engine.dart';
import '../filters/filter_controller.dart';
import '../filters/filter_predicate.dart';

final searchMatchCountProvider = Provider.autoDispose<int?>((ref) {
  final ranked = ref.watch(rankedVenuesProvider).asData?.value;
  if (ranked == null) return null;

  final q = ref.watch(searchQueryProvider);
  if (q.isEmpty) return null; // only show "matches" when searching

  final engine = ref.watch(venueSearchEngineProvider);
  final filters = ref.watch(filtersProvider);

  List<Venue> xs = engine.filter(ranked.venues, q);
  xs = xs
      .where((v) => venuePassesFilters(v, filters, userLoc: ranked.userLoc))
      .toList();
  return xs.length;
}, name: 'searchMatchCountProvider');
