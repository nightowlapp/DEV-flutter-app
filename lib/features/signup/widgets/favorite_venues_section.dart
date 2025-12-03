// lib/features/settings/widgets/favorite_venues_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/buttons/favorite_venue_button.dart';

import '../../../data/providers/favorite_venues/favorite_venues_provider.dart';
import '../../../data/providers/favorite_venues/favorites_providers.dart';

class FavoriteVenuesSection extends ConsumerWidget {
  const FavoriteVenuesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(favoriteVenuesProvider);
    // final favStore = ref.watch(favoriteStoreProvider(venue.id));

    return venuesAsync.when(
      loading: _loadingSkeleton,
      error: (e, _) =>
          Text('Could not load favorites', style: Styles.basicText),
      data: (venues) {
        if (venues.isEmpty) {
          return Text('You haven’t favorited any venues yet.',
              style: Styles.basicText);
        }

        // Keep backend order; for alphabetical by displayName, uncomment next line:
        // venues.sort((a, b) => (a.displayName ?? '').compareTo(b.displayName ?? ''));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are receiving notifications from ${venues.length} '
              'venue${venues.length == 1 ? '' : 's'}',
              style: Styles.basicText,
            ),
            const SizedBox(height: 8),
            ...venues.map(_venueTile),
          ],
        );
      },
    );
  }

  static Widget _venueTile(Venue v) {
    final name = (v.displayName?.trim().isNotEmpty == true)
        ? v.displayName!.trim()
        : v.id; // fallback only if displayName is empty/null

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading:
          const Icon(Icons.favorite, color: owlPurple, size: iconSizeDefault),
      title: Text(name, style: Styles.basicText),
      onTap: () {
        // FavoriteVenueButton(store: favStore, venue: venue),
        // Hook up navigation if you have a details screen:
        // Navigator.of(context).pushNamed(VenueDetailsScreen.routeName, arguments: v.id);
      },
    );
  }

  static Widget _loadingSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        4,
        (i) => Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.08),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
