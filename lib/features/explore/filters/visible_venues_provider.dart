// lib/features/explore/search/visible_venues_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import '../../../data/providers/other_providers.dart';
import '../presentation/ranked_venues_controller.dart';
import '../search/search_controller.dart';
import '../search/search_engine.dart';
import '../filters/filter_controller.dart';
import '../filters/filter_predicate.dart';

final visibleVenuesProvider = Provider.autoDispose<List<Venue>>((ref) {
  final ranked = ref.watch(rankedVenuesProvider).asData?.value;
  if (ranked == null) return const <Venue>[];

  final q = ref.watch(searchQueryProvider);
  final engine = ref.watch(venueSearchEngineProvider);
  final filters = ref.watch(filtersProvider);

  // 1) full ranked snapshot
  var xs = ranked.venues;

  // 2) search within ranked (keeps move animations meaningful)
  if (q.isNotEmpty) xs = engine.filter(xs, q);

  // 3) apply filters
  final userLoc = ranked.userLoc;
  xs = xs
      .where((v) => venuePassesFilters(v, filters, userLoc: userLoc))
      .toList();

  return xs;
}, name: 'visibleVenuesProvider');
