// lib/features/onboarding/choose_favorite_venues_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightowlcode/features/main/widgets/main_app_bar.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/reusable/ui/buttons.dart';
import 'package:nightowlcode/shared/reusable/ui/venue_logo.dart';
import 'package:nightowlcode/assets.dart';

import '../../../core/platform_config.dart';
import '../../../data/providers/other_providers.dart';
import '../../../data/providers/favorite_venues/favorites_providers.dart';
import '../../../data/providers/favorite_venues/favorite_venues_provider.dart';
import '../../../models/venues/venue.dart';
import '../../../shared/constants/styles.dart';

class ChooseFavoriteVenuesScreen extends ConsumerStatefulWidget {
  const ChooseFavoriteVenuesScreen({super.key});

  @override
  ConsumerState<ChooseFavoriteVenuesScreen> createState() =>
      _ChooseFavoriteVenuesScreenState();
}

class _ChooseFavoriteVenuesScreenState
    extends ConsumerState<ChooseFavoriteVenuesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String q) => setState(() => _query = q.trim().toLowerCase());

  Color _counterColor(int selectedCount, int maxSelection) {
    if (selectedCount < 3) return red;
    if (selectedCount < maxSelection) return orange;
    return owlPurple;
  }

  Future<void> _onToggleVenue(BuildContext ctx, Venue v, bool isFav) async {
    final store = ref.read(favoriteStoreProvider(v.id));

    // If adding, pre-check limit to show a nice message before throwing
    if (!isFav) {
      final canAdd = await store.canAdd();
      if (!canAdd && mounted) {
        await showDialog(
          context: ctx,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF121212),
            title: const Text('Too many favorites',
                style: TextStyle(color: Colors.white)),
            content: const Text(
              'You’ve hit your current favorites limit.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('OK', style: TextStyle(color: owlPurple)),
              ),
            ],
          ),
        );
        return;
      }
    }

    try {
      await store.toggle();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // All venues from your SSO (reactive + fast)
    final allVenues = ref.watch(venuesListProvider);

    // Favorite IDs (reactive)
    final favIdsAsync = ref.watch(favoriteVenueIdsProvider);
    final favIds = favIdsAsync.maybeWhen(
      data: (ids) => ids.toSet(),
      orElse: () => <String>{},
    );

    // Progress & limit (reactive)
    final progress = ref.watch(favoritesProgressProvider);
    final selectedCount = progress.current;
    final maxSelection = progress.limit;

    // Filter (case-insensitive) – display ALL when query empty
    List<Venue> displayVenues = allVenues;
    if (_query.isNotEmpty) {
      displayVenues = allVenues
          .where((v) =>
              (_labelFor(v)).toLowerCase().contains(_query) ||
              v.id.toLowerCase().contains(_query))
          .toList();
    }

    // Split into selected vs unselected for the strip + grid
    final selected = displayVenues.where((v) => favIds.contains(v.id)).toList();
    final unselected =
        displayVenues.where((v) => !favIds.contains(v.id)).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    const itemWidth = 60.0;
    const paddingTotal = 40.0;
    const spacingTotal = 8.0;
    final totalWidth = 5 * itemWidth + spacingTotal + paddingTotal;
    final useTwoRows = selected.length == 5 && totalWidth > screenWidth;

    return Scaffold(
      appBar: const MainAppBar(
        titleText: 'Favorite Venues',
        centerTitle: true,
        leading: SizedBox.shrink(),
        actions: [
          CircleAvatar(backgroundImage: const AssetImage(ImagePaths.logo)),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search + Counter
                  Row(
                    children: [
                      Expanded(
                        flex: 8,
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearch,
                          decoration: InputDecoration(
                            hintText: 'Search Venues',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: const Color(0xFF1E1E1E),
                            prefixIcon: Icon(Icons.search, color: owlPurple),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$selectedCount',
                                style: TextStyle(
                                  color: _counterColor(
                                      selectedCount, maxSelection),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(
                                text: '/',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: '$maxSelection',
                                style: TextStyle(
                                  color: owlPurple,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Selected strip
                  if (selected.isNotEmpty) ...[
                    SizedBox(
                      height: 90,
                      child: useTwoRows
                          ? Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 5,
                              runSpacing: 5,
                              children: selected
                                  .map(
                                    (v) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      child: _VenueItem(
                                        venue: v,
                                        isSelected: true,
                                        onTap: () =>
                                            _onToggleVenue(context, v, true),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: selected
                                    .map(
                                      (v) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        child: _VenueItem(
                                          venue: v,
                                          isSelected: true,
                                          onTap: () =>
                                              _onToggleVenue(context, v, true),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                    ),
                    Text(
                      'Tap again to unselect',
                      textAlign: TextAlign.center,
                      style: Styles.smallText,
                    ),
                    SizedBox(
                      height: PlatformConfig.height(context) * 0.01,
                    ),
                    Divider(color: owlPurple),
                    SizedBox(
                      height: PlatformConfig.height(context) * 0.02,
                    ),
                  ],

                  // Grid of unselected venues
                  Expanded(
                    child: Scrollbar(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: unselected.length,
                        itemBuilder: (_, i) {
                          final v = unselected[i];
                          return _VenueItem(
                            venue: v,
                            isSelected: false,
                            onTap: () => _onToggleVenue(context, v, false),
                          );
                        },
                      ),
                    ),
                  ),

                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OwlButton(
                            label: 'Skip',
                            textColor: white,
                            onPressed: () {
                              context.goScreen(MainScreenName.explore);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OwlButton(
                            label: 'Save',
                            textColor: selectedCount > 0 ? white : grey,
                            backgroundColor:
                                selectedCount > 0 ? owlPurple : grey,
                            onPressed: selectedCount > 0
                                ? () {
                                    // Favorites already persisted on tap.
                                    context.goScreen(MainScreenName.explore);
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: PlatformConfig.height(context) * 0.02),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(Venue v) {
    final name = (v.displayName?.isNotEmpty ?? false) ? v.displayName! : v.name;
    return name.trim();
  }
}

/* ---------------------------- UI Building Blocks --------------------------- */

class _VenueItem extends StatelessWidget {
  const _VenueItem({
    required this.venue,
    required this.isSelected,
    required this.onTap,
  });

  final Venue venue;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const baseImage = 50.0;
    const selectedImage = 55.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              _label(),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? owlPurple : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: isSelected ? selectedImage : baseImage,
            height: isSelected ? selectedImage : baseImage,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  isSelected ? Border.all(color: owlPurple, width: 3) : null,
            ),
            child: VenueLogo(
                venue: venue, showTypeIfNoLogo: true), //TODO check if work.
          ),
        ],
      ),
    );
  }

  String _label() {
    final name = (venue.displayName?.isNotEmpty ?? false)
        ? venue.displayName!
        : venue.name;
    return name.trim();
  }
}
