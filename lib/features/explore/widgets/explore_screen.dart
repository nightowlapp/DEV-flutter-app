// lib/features/explore/presentation/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';

import '../../../core/storage/venues_sso.dart';
import '../../../data/providers/other_providers.dart';
import '../../../data/services/media_existence.dart';
import '../filters/filters_popup.dart';
import '../search/search_wiring.dart';
import '../utility/animated_venue_grid.dart';
import '../utility/venue_search_bar.dart';

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
    // Use the SSO’s async to show loading/error once, globally.
    final asyncSso = ref.watch(venuesSsoProvider);
    // Your computed lists still come via providers that read the SSO list.
    final visible = ref.watch(visibleVenuesProvider);
    final ranked = ref.watch(rankedVenuesProvider);
    final Map<String, VenueMediaHealth> mediaById = ranked.maybeWhen(
      data: (s) => s.media,
      orElse: () => const <String, VenueMediaHealth>{},
    );
    final userLoc = ranked.maybeWhen(
      data: (s) => s.userLoc,
      orElse: () => null,
    );

    return Scaffold(
      body: Column(
        children: [
          VenueSearchBar(
            controller: _searchCtrl,
            onTapTune: () => showFiltersPopup(context, ref),
          ),
          const SizedBox(height: verticalSpacerSmall),
          Expanded(
            child: asyncSso.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => Center(
                child: Text('Error: $e', style: const TextStyle(color: red)),
              ),
              data: (_) {
                if (visible.isEmpty) {
                  return const Center(
                    child:
                        Text('No venues found', style: TextStyle(color: red)),
                  );
                }
                return AnimatedVenuesGrid(
                  venues: visible,
                  mediaById: mediaById,
                  userLoc: userLoc,
                  // If your grid needs media/userLoc, keep your existing providers for those,
                  // or create dedicated providers. For now omit or pass null/empty if optional.
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
