// venue_screen_content.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marquee/marquee.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/data/services/like_store.dart';
import 'package:nightowlcode/features/explore/utility/cover_image.dart';
import 'package:nightowlcode/features/explore/utility/offer_today_section.dart';
import 'package:nightowlcode/features/explore/utility/rating_card.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/reusable/ui/buttons.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/distance.dart';
import 'package:nightowlcode/data/services/media_existence.dart';
import 'package:nightowlcode/shared/utility/custom_network_image.dart';
import 'package:nightowlcode/shared/reusable/ui/venue_logo.dart';

import '../../../data/providers/likes_providers.dart';
import '../../../data/providers/favorite_venues/favorites_providers.dart';
import '../../../data/providers/real_time_database_providers.dart';
import '../../../data/providers/venues/venue_media_providers.dart';
import '../../../shared/reusable/ui/buttons/favorite_venue_button.dart';
import '../../../shared/reusable/ui/buttons/like_venue_button.dart';
import '../../../shared/reusable/ui/edit_badge.dart';
import '../../../shared/reusable/ui/verified_badge.dart';
import '../utility/bar_card_screen.dart';
import '../utility/mood_images_section.dart';
import '../../../shared/reusable/venues/venue_tags_grid.dart';
import 'more_info_screen.dart';

// -------------------- LIVE COUNT PROVIDERS --------------------
// Stream<int> -> Riverpod provider so we can watch it in the UI.
final liveVenueCountProvider = StreamProvider.family<int, String>(
  (ref, venueId) => liveVenueCount(venueId));

// (Optional) all counts if you ever need them elsewhere.
final liveAllVenueCountsProvider =
  StreamProvider<Map<String, int>>((ref) => liveAllVenueCounts());

class VenueScreenContent extends ConsumerWidget {
  const VenueScreenContent({
    super.key,
    required this.venue,
    this.media,
    this.userLoc,
    this.walkText, // optional: if you already computed it
    this.isOpen, // optional: border color around logo
    this.tags, // optional: override tags
    this.rating, // optional: show rating card if provided
    this.ratingCount, // optional: "(123)"
    this.onTapOpeningHours,
    this.onTapMoreInfo,
    this.onTapBarCard,
    this.hasBarCard = false,
  });

  final Venue venue;
  final VenueMediaHealth? media;
  final LatLng? userLoc;

  /// Precomputed values / overrides
  final String? walkText;
  final bool? isOpen;
  final List<String>? tags;
  final double? rating;
  final String? ratingCount;

  /// Actions
  final VoidCallback? onTapOpeningHours;
  final VoidCallback? onTapMoreInfo;
  final VoidCallback? onTapBarCard;
  final bool hasBarCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeStore = ref.watch(likeStoreProvider(venue.id));
    final favStore = ref.watch(favoriteStoreProvider(venue.id));
    final asyncMedia = ref.watch(venueMediaBundleProvider(venue.id));

    // ✅ Watch live count as AsyncValue<int>
    final visitsAsync = ref.watch(liveVenueCountProvider(venue.id));
    final int visits = visitsAsync.value ?? 0;

    final int cap = venue.capacity;

    // same threshold you had, but uses live count
    final bool showStats = visits > 10 || (cap > 0 && (visits / cap!) >= 0.20);

    // safe % filled
    final int percentFilled =
      (((visits / cap!) * 100.0).clamp(0.0, 100.0)).round();

    return Column(
      children: [
        // ----- FIXED HEADER -----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: PlatformConfig.height(context) * 0.01),
              CoverImage.fromMedia(
                media: media,
                city: venue.city,
                height: PlatformConfig.height(context) * 0.2,
              ),
              SizedBox(height: PlatformConfig.height(context) * 0.01),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FavoriteVenueButton(store: favStore, venue: venue),
                  const SizedBox(width: allSidePaddingDefault),
                  LikeVenueButton(store: likeStore, venue: venue),
                  const SizedBox(width: allSidePaddingDefault),
                  venue.isVerified ? const VerifiedBadge() : const EditBadge(),
                  const Spacer(),
                  Column(
                    children: [
                      _displayOpeningHours(venue),
                      const SizedBox(height: allSidePaddingDefault),
                      RatingCard(venue: venue),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // ---------- SCROLLABLE AREA ----------
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding:
            const EdgeInsets.symmetric(horizontal: allSidePaddingDefault),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: PlatformConfig.height(context) * 0.05),
                MoodImagesSection(venueId: venue.id),
                SizedBox(height: PlatformConfig.height(context) * 0.05),
                if (venue.tagids.length > 4)
                VenueTagsGrid(
                  tagIds: venue.tagids,
                  viewportWidth: PlatformConfig.width(context),
                  viewportHeight: PlatformConfig.height(context),
                ),
                if (venue.tagids.length > 4)
                SizedBox(height: PlatformConfig.height(context) * 0.05),

                // SizedBox(height: 1000,),

                // Bottom actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      height: PlatformConfig.height(context) * 0.04,
                      width: PlatformConfig.width(context) * 0.35,
                      child: OwlButton(
                        borderRadius: borderRadiusSmall,
                        label: 'More Info',
                        onPressed: () => context.pushNamedPage(
                          MoreInfoScreen.routeName,
                          extra: VenueMoreInfoArgs(
                            venue: venue,
                            media: media,
                            userLoc: userLoc,
                          ),
                        ),
                      ),
                    ),
                    if (venue.isVerified)
                    SizedBox(
                      height: PlatformConfig.height(context) * 0.04,
                      width: PlatformConfig.width(context) * 0.35,
                      child: OwlButton(
                        borderRadius: borderRadiusSmall,
                        label: 'Bar Card',
                        onPressed: () => context.pushNamedPage(
                          BarCardScreen.routeName,
                          extra: BarCardArgs(
                            venueId: venue.id,
                            venueName: venue.displayName,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (showStats) ...[
                  SizedBox(height: PlatformConfig.height(context) * 0.05),
                  const Divider(color: white),
                  SizedBox(height: PlatformConfig.height(context) * 0.05),

                  // Live stats (uses live "visits" + safe capacity)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statPill(
                          context: context,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: visits.toString(),
                                  style: Styles.basicTextHeader
                                    .copyWith(color: owlPurple),
                                ),
                                TextSpan(
                                  text: " Right now",
                                  style: Styles.basicText,
                                ),
                              ],
                            ),
                          ),
                        ),
                        _statPill(
                          context: context,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "$percentFilled",
                                  style: Styles.basicTextHeader
                                    .copyWith(color: owlPurple),
                                ),
                                const TextSpan(
                                  text: "% ",
                                  style: TextStyle(
                                    color: white,
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: "Filled",
                                  style: Styles.basicText,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (asyncMedia.hasValue) ...[
                  SizedBox(height: PlatformConfig.height(context) * 0.05),
                  OfferTodaySection(venueId: venue.id),
                  SizedBox(height: PlatformConfig.height(context) * 0.05),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statPill({required BuildContext context, required Widget child}) {
    return Container(
      height: PlatformConfig.height(context) * 0.04,
      width: PlatformConfig.width(context) * 0.35,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: black,
        border: Border.all(color: white),
        borderRadius: BorderRadius.circular(borderRadiusSmall),
      ),
      child: child,
    );
  }

  // Replace your _displayOpeningHours(Venue v) with this version.
  // It shows yesterday's range if the venue is currently open due to yesterday's overnight window.
  Widget _displayOpeningHours(Venue v) {
    final now = DateTime.now(); // make sure this is venue-local if you use TZs
    final status = v.openingHours.statusAt(now);

    final r = venue.openingHoursToday();

    final baseStyle = Styles.boldText.copyWith(letterSpacing: 1.2);
    final supStyle = Styles.smallText.copyWith(fontWeight: FontWeight.w600);

    final isOpenNow = status.phase == OpeningPhase.open;
    final isClosedForDisplay = !isOpenNow && r.isClosed;

    return SizedBox(
      width: 130,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapOpeningHours,
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          child: Ink(
            decoration: BoxDecoration(
              color: black,
              borderRadius: BorderRadius.circular(borderRadiusSmall),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: isClosedForDisplay
              ? Text('Closed today', style: baseStyle.copyWith(color: red))
              : RichText(
                text: TextSpan(
                  style: baseStyle,
                  children: [
                    TextSpan(text: '${r.open} - ${r.close}'),
                    if (r.nextDay)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Transform.translate(
                        offset: const Offset(2, -5),
                        child: Text('+1', style: supStyle),
                      ),
                    ),
                  ],
                ),
              ),
          ),
        ),
      ),
    );
  }

}
