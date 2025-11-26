// lib/features/main/right_drawer/sections/favorites_section_right_drawer.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';

import '../../../../data/providers/favorite_venues/favorite_venues_provider.dart';
import '../../../../data/providers/favorite_venues/favorites_providers.dart';
import '../../../../shared/constants/styles.dart';
import '../../../../shared/constants/values.dart';
import '../../../../shared/constants/colors.dart';
import '../../../../shared/reusable/ui/venue_logo.dart';

// ⬅️ bring in the extension with goToMapAndFocusVenue
import '../../../../navigation/nav_shortcuts.dart';

class FavoritesSectionRightDrawer extends ConsumerWidget {
  const FavoritesSectionRightDrawer({super.key, this.minSlots = 5});
  final int minSlots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(favoritesProgressProvider);
    final countAsync = ref.watch(favoritesCountProvider);
    final venuesAsync = ref.watch(favoriteVenuesProvider);

    final currentCount = countAsync.maybeWhen(data: (c) => c, orElse: () => 0);
    final currentText =
        countAsync.maybeWhen(data: (c) => '$c', orElse: () => '');
    final limitText = progress.unlimited ? '∞' : '${progress.limit}';
    final half = progress.unlimited ? 0 : (progress.limit / 2).floor();

    final Color brand = owlPurple;
    final Color currentColor =
        progress.unlimited ? brand : (currentCount <= half ? red : brand);
    final Color limitColor = brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Center(child: Text('Favorites', style: Styles.boldText)),
            Positioned(
              right: 0,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: currentText,
                      style: Styles.basicText.copyWith(
                          color: currentColor, fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                        text: ' / ',
                        style: Styles.basicText.copyWith(color: white)),
                    TextSpan(
                      text: limitText,
                      style: Styles.basicText.copyWith(
                          color: limitColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: verticalSpacerSmall),
        SizedBox(
          height: 50,
          child: venuesAsync.when(
            loading: () => const LoadingIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (venues) {
              if (venues.isEmpty) {
                return Center(
                  child: Text('No favorites',
                      style: Styles.smallText.copyWith(color: red)),
                );
              }

              final now = DateTime.now();
              final list = [...venues]..sort((a, b) {
                  final ao = a.isOpenNow(now);
                  final bo = b.isOpenNow(now);
                  return (bo ? 1 : 0) - (ao ? 1 : 0);
                });

              final slots = math.max(list.length, minSlots);
              const itemPad = horizontalSpacerSmall;
              const logoSize = logoIconSize;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(slots, (i) {
                    if (i >= list.length) {
                      return const SizedBox(width: itemPad, height: 50);
                    }
                    final v = list[i];

                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: itemPad / 2),
                      child: VenueLogo(
                        venue: v,
                        size: logoSize,
                        shape: VenueLogoShape.circle,
                        tooltip:
                            v.displayName.isNotEmpty ? v.displayName : v.name,
                        onTap: () async {
                          await context.goToMapAndFocusVenue(ref, v, zoom: 16);
                        },
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
