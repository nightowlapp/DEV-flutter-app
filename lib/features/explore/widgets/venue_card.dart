// lib/shared/reusable/venues/venue_card.dart
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/explore/utility/cover_image.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/distance.dart';

import '../../../data/services/media_existence.dart';
// ⬇️ brings in context.goToMapAndFocusVenue(ref, venue, zoom: ...)
import '../../../navigation/nav_shortcuts.dart';

class VenueCard extends ConsumerWidget {
  const VenueCard({
    super.key,
    required this.venue,
    this.userLocation,
    this.media,
    this.onTap,
    this.onLongPress, // optional override
    this.overrideFallbackAsset,
    this.longPressZoom = 15,
    this.hapticOnLongPress = true,
  });

  final Venue venue;
  final LatLng? userLocation;
  final VenueMediaHealth? media;

  /// Optional tap handler (kept as-is)
  final VoidCallback? onTap;

  /// Optional long-press override. If not provided, we navigate to Map.
  final VoidCallback? onLongPress;

  /// Optional override for the fallback asset.
  /// If null, `CoverImage.fromMedia` will use the city asset automatically.
  final String? overrideFallbackAsset;

  /// Zoom level used when long-pressing to open in Map.
  final double longPressZoom;

  /// Whether to provide light haptic feedback on long-press.
  final bool hapticOnLongPress;

  static final AutoSizeGroup _titleGroup = AutoSizeGroup();



  Widget _pill(String text, {Color? bg, Color? fg}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
    decoration: BoxDecoration(
      color: bg ?? (text.isNotEmpty ? black : transparent),
      borderRadius: BorderRadius.circular(borderRadiusDefault),
    ),
    child: AutoSizeText(
      text,
      style: Styles.smallText.copyWith(color: fg),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = venue.displayName.isNotEmpty ? venue.displayName : venue.name;
    final age = venue.defaultAgeRestriction;
    final isVerified = venue.isVerified;
    final String walkText = Distance.walkText(userLocation, venue);

    return Material(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
      color: Colors.transparent,
      child: InkWell(
        // single tap still uses provided callback
        onTap: onTap,
        // ✅ long-press: go to Map and focus venue (or use custom override)
        onLongPress: () async {
          if (hapticOnLongPress) {
            HapticFeedback.selectionClick();
          }
          if (onLongPress != null) {
            onLongPress!();
            return;
          }
          await context.goToMapFocusAndOpenVenue(ref, venue, zoom: longPressZoom);
        },
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Keep the same 0.75 aspect as before
            final width = constraints.maxWidth;
            final height = width / 0.75;

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: isVerified ? green : transparent),
                borderRadius: BorderRadius.circular(borderRadiusMedium),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: height,
                child: Stack(
                  children: [
                    // ✅ Use the shared CoverImage
                    Positioned.fill(
                      child: overrideFallbackAsset == null
                        ? CoverImage.fromMedia(
                          media: media,
                          city: venue.city,
                          height: height,
                          fit: BoxFit.cover,
                        )
                        : CoverImage(
                          imageUrl: (media?.coverExists == true &&
                            (media?.coverUrl?.isNotEmpty ?? false))
                            ? media!.coverUrl
                            : null,
                          fallbackAsset: overrideFallbackAsset,
                          height: height,
                          fit: BoxFit.cover,
                        ),
                    ),
                    // Title pill (top)
                    Positioned(
                      top: 2,
                      left: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        decoration: BoxDecoration(
                          color: black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(borderRadiusDefault),
                        ),
                        child: Center(
                          child: AutoSizeText(
                            title, // use your computed title
                            group: isVerified ? null : _titleGroup,                    // keep all cards aligned (optional)
                            maxLines: 1,
                            // overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            // Either use preset steps (faster)...
                            presetFontSizes: const[18, 16, 14, 12], // tries in order
                            // ...or min/max with a step (slightly more work per layout):
                            // minFontSize: 12,
                            // maxFontSize: 18,
                            stepGranularity: 1,
                            style: Styles.basicText.copyWith(
                              // color: isVerified ? green : white,
                              fontWeight: isVerified ? FontWeight.w700 : FontWeight.w100,
                              // letterSpacing: isVerified ? 1.5:1,
                              // Base size here is the "max" when using presetFontSizes
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),


                    // Bottom pills
                    // Bottom pills
                    // 2) Replace the bottom pills block in build() with this:
                    Positioned(
                      bottom: 2,
                      left: 2,
                      right: 2,
                      child: Builder(builder: (context) {
                        final now = DateTime.now(); // use venue-local time if you convert elsewhere
                        final isOpen = venue.isOpenNow(now);

                        int minutesLeft = -1;
                        if (isOpen) {
                          minutesLeft = venue.closeTimeToday().difference(now).inMinutes;
                          if (minutesLeft < 0) minutesLeft = 0; // guard against clock drift
                        }
                        final closingSoon = isOpen && minutesLeft <= 60;

                        final left = closingSoon
                            ? _pill('Closing soon', fg: orange)
                            : (isOpen
                            ? _pill(walkText) // show distance when open
                            : _pill('Closed', fg: red));

                        final right = _pill('$age+');

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            left,
                            right,
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
