import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/features/explore/utility/rating_card.dart';
import 'package:nightowlcode/features/main/widgets/main_app_bar.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/country_code.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/distance.dart';
import 'package:nightowlcode/data/services/media_existence.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

import '../../../core/storage/storage_url.dart';
import '../../../data/providers/likes_providers.dart';
import '../../../data/providers/favorite_venues/favorite_limit_provider.dart';
import '../../../data/providers/favorite_venues/favorites_providers.dart';
import '../../../shared/constants/icons.dart';
import '../../../shared/reusable/ui/buttons/favorite_venue_button.dart';
import '../../../shared/reusable/ui/buttons/like_venue_button.dart';
import '../../../shared/reusable/ui/edit_badge.dart';
import '../../../shared/reusable/ui/owl_snack.dart';
import '../../../shared/reusable/ui/venue_logo.dart';
import '../../../shared/reusable/ui/verified_badge.dart';
import '../../../shared/utility/city_asset.dart';
import '../utility/cover_image.dart';
import '../utility/opening_info_header_bar.dart';
import 'venue_main_screen.dart';

// ---- Args -------------------------------------------------------------------

class VenueMoreInfoArgs {
  final Venue venue;
  final VenueMediaHealth? media;
  final LatLng? userLoc;
  const VenueMoreInfoArgs({required this.venue, this.media, this.userLoc});
}

// ---- Screen -----------------------------------------------------------------

class MoreInfoScreen extends ConsumerWidget {
  static const routeName = 'moreInfo';

  final Venue venue;
  final VenueMediaHealth? media;
  final LatLng? userLoc;

  const MoreInfoScreen({
    super.key,
    required this.venue,
    this.media,
    this.userLoc,
  });

  String get _title =>
      venue.displayName.isNotEmpty ? venue.displayName : venue.name;

  // Header (cover) ------------------------------------------------------------
  Widget _header(BuildContext context) {
    final h = PlatformConfig.height(context) * 0.2; // a bit taller feels nicer
    return CoverImage(
      imageUrl: StorageUrl.normalize(venue.heroImageUrl ?? ''),
      height: h,
      hideIfEmpty: false,
      fallbackAsset: assetForCity(venue.city),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeStore = ref.watch(likeStoreProvider(venue.id));
    final favStore = ref.watch(
      favoriteStoreProvider(venue.id),
    );

    final logo =
    VenueLogo(
      venue: venue,
      size: iconSizeLarge + 4,
    );
    final price = venue.effectiveEntryPrice(DateTime.now());
    final bool hasPrice = (price ?? 0) > 0;

    return Scaffold(
      backgroundColor: black,
      appBar: MainAppBar(
        titleText: _title,
        showBack: true,
        centerTitle: true,
        action: logo,
        backgroundColor: black,
      ),

      // Use slivers to avoid internal SliverPadding/layout issues
      body: CustomScrollView(
        slivers: [
          // Cover image
          SliverToBoxAdapter(child: _header(context)),

          // Page content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                // Top row: icons + rating card
                Row(
                  children: [
                    SizedBox(height: PlatformConfig.height(context) * 0.01),

                    FavoriteVenueButton(store: favStore, venue: venue),
                    const SizedBox(width: allSidePaddingDefault),
                    LikeVenueButton(
                      store: likeStore,
                      venue: venue,
                    ),
                    const SizedBox(width: allSidePaddingDefault),
                    venue.isVerified ? const VerifiedBadge() : EditBadge(venue: venue,),

                    const Spacer(),
                    RatingCard(venue: venue), // will be replaced below
                  ],
                ),
                SizedBox(
                  height: PlatformConfig.height(context) * 0.05,
                ),

                OpeningInfoHeaderBar(
                    openingHours: venue.openingHours,
                    defaultAgeRestriction: venue.defaultAgeRestriction,
                    initiallyExpanded: true),

                SizedBox(
                  height: PlatformConfig.height(context) * 0.05,
                ),
                Row(
                  children: [
                    // LEFT: tappable → show snack
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // onTap: () => OwlSnack.show(), TODO navigation
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(locationPinIcon, size: iconSizeLarge),
                                SizedBox(
                                    width:
                                        PlatformConfig.width(context) * 0.01),
                                Column(
                                  children: [
                                    Text(Distance.distanceText(userLoc, venue),
                                        style: Styles.boldText),
                                    Text(Distance.walkText(userLoc, venue),
                                        style: Styles.boldText),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(
                                height: PlatformConfig.height(context) * 0.002),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (venue.city != null ||
                                    venue.city.trim().isNotEmpty)
                                  Text(
                                    Utility.formatString(venue.city),
                                    style: Styles.basicText.copyWith(
                                        color: blue, fontSize: fontSizeSmaller),
                                  )
                                else
                                  SizedBox.shrink(),
                                Row(
                                  children: [
                                    if (venue.countryCode != null ||
                                        venue.countryCode.trim().isNotEmpty)
                                      Text(
                                        venue.countryCode.toCountryName(),
                                        style: Styles.basicText.copyWith(
                                            color: blue,
                                            fontSize: fontSizeSmallest),
                                      )
                                    // SizedBox(width: PlatformConfig.width(context) * 0.005)
                                    else
                                      SizedBox.shrink(),
                                    // if (venue.timeZoneId != null || venue.timeZoneId!.trim().isNotEmpty)
                                    // Text(venue.timeZoneId!, style: Styles.basicText.copyWith(fontSize: fontSizeSmallest),)
                                    // else SizedBox.shrink(),
                                  ],
                                ),
                              ],
                            )
                          ]),
                    ),

                    const Spacer(),

                    // RIGHT: wrapped too, but onTap is a no-op
                    if (venue.type != VenueType.unknown)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          OwlSnack.show(context,
                              title: 'Venue Type',
                              message:
                                  '${venue.displayName} is a ${Utility.formatString(venue.type.name)}');
                        },
                        child: Row(
                          children: [
                            SizedBox(
                                width: PlatformConfig.width(context) * 0.01),
                            Column(
                              children: [
                                Text(Utility.formatString(venue.type.name),
                                    style: Styles.boldText),
                              ],
                            ),
                            Icon(venue.type.icon, size: iconSizeLarge),
                          ],
                        ),
                      ),
                  ],
                ),
                if (venue.type != VenueType.unknown)
                  SizedBox(
                    height: PlatformConfig.height(context) * 0.03,
                  ),

                if (venue.isVerified)
                  Row(
                    children: [
                      // LEFT: tappable (shows snack)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque, // bigger tap target
                        onTap: () => OwlSnack.show(
                          context,
                          title: 'Dresscode Today',
                          message:
                              'The dresscode today is: ${Utility.formatString(venue.effectiveDressCode(DateTime.now()).name)}',
                        ),
                        child: Row(
                          children: [
                            Icon(dressCodeIcon, size: iconSizeLarge),
                            SizedBox(
                                width: PlatformConfig.width(context) * 0.01),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(''),
                                Text(
                                  Utility.formatString(
                                    venue
                                        .effectiveDressCode(DateTime.now())
                                        .name,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (venue.isVerified) const Spacer(),

                      // RIGHT: wrapped too, but onTap does nothing
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!hasPrice)
                                  Text('Free\nEntrance', style: Styles.boldText)
                                else ...[
                                  Text(''), // blank line above
                                  Text(
                                    price
                                        .toString(), // or '€${price.toStringAsFixed(0)}'
                                    style: Styles.boldText,
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(
                                width: PlatformConfig.width(context) * 0.01),
                            Icon(hasPrice ? euroIcon : freeIcon,
                                size: iconSizeLarge),
                          ],
                        ),
                        onTap: () {}, // intentionally no-op TODO
                      ),
                    ],
                  ),

                // SizedBox(height: PlatformConfig.height(context) * 0.05,),

                // Container(child: Text(Venue.links),)

                // Description (optional)
                if (venue.description.trim().isNotEmpty && venue.isVerified)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: black,
                      border: Border.all(color: grey, width: 0.7),
                      borderRadius: BorderRadius.circular(borderRadiusMedium),
                    ),
                    child: Text(
                      venue.description,
                      style: Styles.basicText,
                    ),
                  ),
                SizedBox(
                  height: PlatformConfig.height(context) * 0.05,
                ),

                //TODO total visits? Total likes? Total favorites? Email? Phone?

                // RatingSummary(venue), TODO
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
