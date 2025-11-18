// lib/features/explore/presentation/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_screen.dart';

import '../../../data/providers/venues/venue_media_providers.dart';
import '../../../data/services/location/location_providers.dart';
import '../../../data/services/media_existence.dart';
import '../filters/filter_controller.dart';
import '../filters/filters_popup.dart';
import '../ranking/explore_ranked_providers.dart';
import '../search/search_controller.dart';
import '../search/search_engine.dart';
import '../search/search_wiring.dart';
import '../utility/animated_venue_grid.dart';
import '../search/venue_search_bar.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      wireSearchController(ref, _searchCtrl); // ← hook search logic
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final rankedVenuesAv = ref.watch(exploreRankedVenuesProvider);

    // Latest user location (nullable is fine for distance labels)
    final userLoc =
    ref.watch(latLngSafeStreamProvider).maybeWhen(data: (p) => p, orElse: () => null);

    return Scaffold(
      body: Column(
        children: [
          VenueSearchBar(
            controller: _searchCtrl,
            onTapTune: () => showFiltersPopup(context, ref),
          ),
          const SizedBox(height: verticalSpacerSmall),
          Expanded(
            child: rankedVenuesAv.when(
              loading: () => const LoadingIndicator(), // ⬅️ either loading
              error: (e, _) {return const LoadingIndicator();},
              data: (venues) {
                // Search
                final query = ref.watch(searchQueryProvider);
                final engine = ref.watch(venueSearchEngineProvider);
                final filters = ref.watch(filtersProvider);

                final mediaById = <String, VenueMediaHealth>{};
                final Iterable<Venue> top = venues.take(64);
                for (final v in top) {
                  final av = ref.watch(venueMediaProvider(v.id));
                  final m = av.maybeWhen(data: (h) => h, orElse: () => null);
                  if (m != null) mediaById[v.id] = m;
                }

                if (venues.isEmpty) {
                  return const Center(
                    child: Text('No venues nearby', style: TextStyle(color: red)),
                  );
                }
                return AnimatedVenuesGrid(
                  venues: venues,          // ⬅️ already ranked
                  mediaById: mediaById,    // ⬅️ fills progressively
                  userLoc: userLoc,
                ); // ⬅️ or your own grid/list
              },
            ),
          ),
        ],
      ),
    );
  }
}