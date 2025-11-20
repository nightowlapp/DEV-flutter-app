// lib/features/explore/presentation/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/reusable/ui/loading/error_screen.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_screen.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/services/location/location_providers.dart';
import '../filters/filters_popup.dart';
import '../ranking/explore_ranked_providers.dart';
import '../utility/animated_venue_grid.dart';
import '../search/venue_search_bar.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    // if you need to wire search:
    // WidgetsBinding.instance.addPostFrameCallback((_) => wireSearchController(ref, _searchCtrl));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final venuesAv = ref.watch(exploreRankedVenuesProvider);
    final locAv = ref.watch(latLngSafeStreamProvider);
    final hasLoc = locAv.maybeWhen(data: (_) => true, orElse: () => false);
//TODO need location in here.
    return Scaffold(
      body: Column(
        children: [
          VenueSearchBar(
            controller: _searchCtrl,
            onTapTune: () => showFiltersPopup(context, ref),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: venuesAv.when(
              data: (venues) => AnimatedVenuesGrid(
                venues: venues,
                mediaById: const {},
                userLoc: locAv.maybeWhen(data: (p) => p, orElse: () => null),
              ),
              loading: () => const LoadingScreen(),
              error: (e, _) => const ErrorScreen(),
            ),
          ),
        ],
      ),
    );
  }
}
