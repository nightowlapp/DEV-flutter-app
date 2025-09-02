// lib/features/explore/search/explore_filtered_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/explore/search/search_engine.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import '../../../data/other_providers.dart';
import '../presentation/ranked_venues_controller.dart';
import 'search_controller.dart';

final exploreFilteredVenuesProvider = Provider.autoDispose<List<Venue>>((ref) {
  final ranked = ref.watch(rankedVenuesProvider).asData?.value;
  final engine = ref.watch(venueSearchEngineProvider);
  final q = ref.watch(searchQueryProvider);
  final base = ranked?.venues ?? const <Venue>[];

  // (Optional) provide user location for distance tokens like "within:5km"
  final list = engine.filter(base, q);
  return list;
});
