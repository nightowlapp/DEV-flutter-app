// lib/features/explore/presentation/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';

import '../filters/filters_popup.dart';
import '../filters/visible_venues_provider.dart';
import '../presentation/ranked_venues_controller.dart';
import '../search/search_wiring.dart';
import '../utility/animated_venue_grid.dart';
import '../utility/venue_search_bar.dart';
import '../search/explore_filtered_provider.dart';

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
    final async = ref.watch(rankedVenuesProvider);
    final filtered = ref.watch(exploreFilteredVenuesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            VenueSearchBar(controller: _searchCtrl,
                onTapTune: () => showFiltersPopup(context, ref)),
            const SizedBox(height: verticalSpacerSmall),
            Expanded(
              child: async.when(
                loading: () => const LoadingIndicator(),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: red))),
                data: (state) {
                  final visible = ref.watch(visibleVenuesProvider);
                  if (visible.isEmpty) {
                    return const Center(child: Text('No venues found', style: TextStyle(color: red)));
                  }
                  if (filtered.isEmpty) { //TODO need both?
                    return const Center(child: Text('No venues found', style: TextStyle(color: red)));
                  }
                  return AnimatedVenuesGrid(
                    venues: visible,
                    mediaById: state.media,
                    userLoc: state.userLoc,
                    // datasetKey optional; your grid can auto-fingerprint as you added
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
