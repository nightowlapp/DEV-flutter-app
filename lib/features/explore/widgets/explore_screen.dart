// lib/features/explore/presentation/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
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
              loading: () => _ExploreSkeleton(showLocationHint: !hasLoc),
              error: (e, _) => _ExploreSkeleton(
                showLocationHint: !hasLoc,
                errorText: 'Couldn’t load venues.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton({this.showLocationHint = false, this.errorText});
  final bool showLocationHint;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (errorText != null) ...[
          Text(errorText!, style: const TextStyle(color: red)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        // simple shimmer-ish placeholders; replace with your own
        Wrap(
          spacing: 12, runSpacing: 12,
          children: List.generate(6, (_) => _box()),
        ),
        if (showLocationHint) ...[
          const SizedBox(height: 18),
          Text('Waiting for location…', style: const TextStyle(color: grey)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              final s = await Permission.location.request();
              if (s.isGranted) {
                // nudge location/venue providers to recompute
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location enabled')),
                );
              }
            },
            child: const Text('Enable location'),
          ),
        ],
      ]),
    );
  }

  Widget _box() => Container(
    width: 110, height: 90,
    decoration: BoxDecoration(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
