// lib/features/explore/presentation/screens/explore_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/reusable/ui/loading/error_screen.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_screen.dart';

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
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshVenues() async {
    // Force recompute on next build
    ref.invalidate(exploreRankedVenuesProvider);
    ref.invalidate(exploreVisibleVenuesProvider);

    // If your venues come from other providers that cache data,
    // you can invalidate those too, e.g.:
    // ref.invalidate(allVenuesListProvider);
    // ref.invalidate(venuesLocalBootDoneProvider);

    // Small delay so the RefreshIndicator has time to show + rebuild
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Widget build(BuildContext context) {
    // ranked → search → filters
    final venuesAv = ref.watch(exploreVisibleVenuesProvider);
    final locAv = ref.watch(latLngSafeStreamProvider);

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
                onRefresh: _refreshVenues, // 👈 pull-to-refresh hook
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
