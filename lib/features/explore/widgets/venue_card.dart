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

import '../../../core/storage/storage_url.dart';
import '../../../data/providers/time_ticker_provider.dart';
import '../../../data/services/media_existence.dart';
import '../../../navigation/nav_shortcuts.dart';
import '../../../shared/utility/city_asset.dart';

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

  Widget _pill(
      String text, {
        Color? bg,
        Color? fg,
        Key? key,
      }) =>
      Container(
        key: key,
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

    // ⏱ watch global time ticker (updates ~every 30s)
    final nowAsync = ref.watch(timeTickerProvider);
    final now = nowAsync.asData?.value ?? DateTime.now();

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
                      child: CoverImage(
                        imageUrl: StorageUrl.normalize(venue.coverImageUrl ?? ''),
                        height: height,
                        fit: BoxFit.cover,
                        hideIfEmpty: false,
                        fallbackAsset: overrideFallbackAsset ?? assetForCity(venue.city),
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
                          final status = venue.openingHours.statusAt(now);
                          final isOpen =
                              status.phase == OpeningPhase.open;

                          // --- Closing soon logic (when already open) ---
                          int minutesLeft = -1;
                          if (isOpen) {
                            minutesLeft = venue
                                .closeTimeToday()
                                .difference(now)
                                .inMinutes;
                            if (minutesLeft < 0) minutesLeft = 0;
                          }
                          final closingSoon =
                              isOpen && minutesLeft <= 60;

                          // --- Opening soon logic (when currently closed) ---
                          int minutesUntilOpen = -1;
                          final nowM = now.hour * 60 + now.minute;

                          if (status.openMinutes != null) {
                            if (status.phase ==
                                OpeningPhase.opensLaterToday) {
                              // Same-day opening later
                              minutesUntilOpen =
                                  status.openMinutes! - nowM;
                            } else if (status.phase ==
                                OpeningPhase.opensTomorrow) {
                              // Opening tomorrow, compute across midnight
                              minutesUntilOpen =
                                  (24 * 60 - nowM) +
                                      status.openMinutes!;
                            }
                          }

                          final openingSoon = !isOpen &&
                              minutesUntilOpen >= 0 &&
                              minutesUntilOpen <= 60;

                          // --- Decide label + color for left pill ---
                          String leftLabel;
                          Color? leftFg;

                          if (closingSoon) {
                            leftLabel = 'Closing soon';
                            leftFg = yellow;
                          } else if (openingSoon) {
                            leftLabel = 'Opening soon';
                            leftFg = blue;
                          } else if (isOpen) {
                            leftLabel = walkText;
                            leftFg = null;
                          } else {
                            leftLabel = 'Closed';
                            leftFg = red;
                          }

                          final right = _pill('$age+');

                          return Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              // 🔥 Smooth transition between states
                              AnimatedSwitcher(
                                duration:
                                const Duration(milliseconds: 250),
                                transitionBuilder:
                                    (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: SizeTransition(
                                        sizeFactor: animation,
                                        axis: Axis.horizontal,
                                        child: child,
                                      ),
                                    ),
                                child: _pill(
                                  leftLabel,
                                  fg: leftFg,
                                  key: ValueKey(leftLabel),
                                ),
                              ),
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
      style: Styles.basicText,
    );
  }
}
