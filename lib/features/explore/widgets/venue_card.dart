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
import '../../../navigation/nav_shortcuts.dart';

class VenueCard extends ConsumerWidget {
  const VenueCard({
    super.key,
    required this.venue,
    this.userLocation,
    this.media,
    this.onTap,
    this.onLongPress,
    this.overrideFallbackAsset,
    this.longPressZoom = 15,
    this.hapticOnLongPress = true,
  });

  final Venue venue;
  final LatLng? userLocation;
  final VenueMediaHealth? media;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? overrideFallbackAsset;
  final double longPressZoom;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width / 0.75;

        return Container(
          // OUTER BORDER – always visible
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
            border: Border.all(
              color: isVerified ? green : Colors.transparent,
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadiusMedium),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              onLongPress: () async {
                if (hapticOnLongPress) {
                  HapticFeedback.selectionClick();
                }
                if (onLongPress != null) {
                  onLongPress!();
                  return;
                }
                await context.goToMapFocusAndOpenVenue(
                  ref,
                  venue,
                  zoom: longPressZoom,
                );
              },
              borderRadius: BorderRadius.circular(borderRadiusMedium),
              child: SizedBox(
                height: height,
                child: Stack(
                  children: [
                    // Background image
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

                    // Title pill
                    Positioned(
                      top: 2,
                      left: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: black.withOpacity(0.7),
                          borderRadius:
                          BorderRadius.circular(borderRadiusDefault),
                        ),
                        child: Center(
                          child: VenueTitle(title),
                        ),
                      ),
                    ),

                    // Bottom pills
                    Positioned(
                      bottom: 2,
                      left: 2,
                      right: 2,
                      child: Builder(
                        builder: (context) {
                          final now = DateTime.now();
                          final isOpen = venue.isOpenNow(now);

                          int minutesLeft = -1;
                          if (isOpen) {
                            minutesLeft =
                            venue.closeTimeToday().difference(now).inMinutes;
                            if (minutesLeft < 0) minutesLeft = 0;
                          }
                          final closingSoon = isOpen && minutesLeft <= 60;

                          final left = closingSoon
                            ? _pill('Closing soon', fg: orange)
                            : (isOpen
                              ? _pill(walkText)
                              : _pill('Closed', fg: red));

                          final right = _pill('$age+');

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              left,
                              right,
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class VenueTitle extends StatelessWidget {
  final String text;
  const VenueTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Styles.basicText
    );
  }
}
