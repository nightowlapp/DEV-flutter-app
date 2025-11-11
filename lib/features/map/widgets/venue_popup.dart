import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/utility/utility.dart';
import 'package:nightowlcode/shared/reusable/ui/buttons.dart';

import '../../../core/platform_config.dart';
import '../../../data/providers/favorite_venues/favorites_providers.dart';
import '../../../data/providers/likes_providers.dart';
import '../../../shared/constants/icons.dart';
import '../../../shared/constants/values.dart';
import '../../../shared/reusable/ui/buttons/favorite_venue_button.dart';
import '../../../shared/reusable/ui/buttons/like_venue_button.dart';
import '../../../shared/reusable/ui/edit_badge.dart';
import '../../../shared/reusable/ui/verified_badge.dart';
import '../../explore/utility/mood_images_section.dart';
import '../../../shared/reusable/venues/venue_tags_grid.dart';
import '../utility/rating_display.dart';

// NEW: for chained navigation Explore → Venue → More Info
import 'package:nightowlcode/navigation/nav_shortcuts.dart';

Future<void> showVenuePopupSheet(
  BuildContext context, {
    required Venue venue,
    VoidCallback? onGo,
    VoidCallback? onClose,
    Widget? body,
    double initialSize = 0.47,
    double minSize = 0.2,
    double maxSize = 0.9,
  }) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => _VenueDraggableSheet(
      venue: venue,
      onGo: onGo,
      onClose: onClose,
      body: body,
      initialSize: initialSize,
      minSize: minSize,
      maxSize: maxSize,
    ),
  );
}

class _VenueDraggableSheet extends StatelessWidget {
  const _VenueDraggableSheet({
    required this.venue,
    this.onGo,
    this.onClose,
    this.body,
    required this.initialSize,
    required this.minSize,
    required this.maxSize,
  });

  final Venue venue;
  final VoidCallback? onGo;
  final VoidCallback? onClose;
  final Widget? body;
  final double initialSize;
  final double minSize;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: initialSize,
      minChildSize: minSize,
      maxChildSize: maxSize,
      snap: true,
      snapSizes: [minSize, initialSize, maxSize],
      builder: (context, scrollController) {
        return _VenuePopupContent(
          venue: venue,
          scrollController: scrollController,
          onGo: onGo,
          onClose: () {
            Navigator.of(context).maybePop();
            onClose?.call();
          },
          body: body,
        );
      },
    );
  }
}

class _VenuePopupContent extends ConsumerWidget {
  const _VenuePopupContent({
    required this.venue,
    required this.scrollController,
    this.onGo,
    this.onClose,
    this.body,
  });

  final Venue venue;
  final ScrollController scrollController;
  final VoidCallback? onGo;
  final VoidCallback? onClose;
  final Widget? body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = venue.displayName.isNotEmpty ? venue.displayName : venue.name;
    final typeLabel =
      venue.type == VenueType.unknown ? '' : Utility.formatString(venue.type.name);
    final likeStore = ref.watch(likeStoreProvider(venue.id));
    final favStore = ref.watch(favoriteStoreProvider(venue.id));

    final double avg = venue.rating ?? 0.0;
    final int count = venue.ratingCount;

    // green outline when verified
    final borderSide =
      venue.isVerified ? BorderSide(color: green, width: 1.4) : BorderSide.none;

    return Material(
      color: black,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(borderRadiusDefault)),
        side: borderSide,
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // drag handle
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: grey,
                      borderRadius: BorderRadius.circular(borderRadiusSmallest),
                    ),
                  ),

                  // ===== TOP ROW: TYPE | NAME | CLOSE =====
                  Row(
                    children: [
                      // type pill
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: transparent,
                          borderRadius: BorderRadius.circular(borderRadiusSmall),
                          border: Border.all(color: grey, width: 0.7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(venue.type.icon, size: iconSizeSmall, color: white),
                            if (typeLabel.isNotEmpty) ...[
                              Text(typeLabel, style: Styles.smallText),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AutoSizeText(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Styles.basicTextHeader.copyWith(fontSize: fontSizeMedium),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // _tinyIconButton(
                          //   icon: editIcon,
                          //   color: grey,
                          //   onPressed: onClose, // or your onEdit TODO
                          // ),
                          _tinyIconButton(
                            icon: closeIcon,
                            color: grey,
                            onPressed: onClose,
                          ),
                        ],
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      RatingDisplay(rating: avg, count: count),
                      const Spacer(),
                      _displayOpeningHours(venue),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      FavoriteVenueButton(store: favStore, venue: venue),
                      const SizedBox(width: allSidePaddingDefault),
                      LikeVenueButton(store: likeStore, venue: venue),
                      const SizedBox(width: allSidePaddingDefault),
                      venue.isVerified ? const VerifiedBadge() : EditBadge(venue: venue,),
                      const Spacer(),
                      OwlButton(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        fullWidth: false,
                        onPressed: onGo,
                        label: "Directions",
                        textStyle: Styles.basicText.copyWith(color: blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),


          // ===== SCROLLABLE BODY AREA =====
          SliverToBoxAdapter(
            child:
            Column(
              children: [
                MoodImagesSection(venueId: venue.id),

                (venue.tagids.length > 4) ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        VenueTagsGrid(
                          tagIds: venue.tagids,
                          viewportWidth: PlatformConfig.width(context),
                          viewportHeight: PlatformConfig.height(context),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ) : const SizedBox.shrink(),
              ],
            ),
          ),

            SliverToBoxAdapter(
              //TODO AMOUNT OF USERS.
            ),

          // ===== BREADCRUMB + MORE INFO BUTTON (BOTTOM) =====
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                50,
                0,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    height: PlatformConfig.height(context) * 0.04,
                    width: PlatformConfig.width(context) * 0.35,
                    child: OwlButton(
                      borderRadius: borderRadiusSmall,
                      label: 'More Info',
                      fullWidth: false,
                      onPressed: () async {
                        // Close the popup first, then navigate through Explore → Venue → More Info
                        final root = Navigator.of(context, rootNavigator: true);
                        root.pop(); // dismiss sheet
                        // Give the pop a moment; then chain navigation
                        await Future.delayed(const Duration(milliseconds: 50));
                        root.context.goToExploreVenueMoreInfo(venue);
                      },
                    ),),
                  if (venue.isVerified)
                  SizedBox(
                    height: PlatformConfig.height(context) * 0.04,
                    width: PlatformConfig.width(context) * 0.35,
                    child: OwlButton(
                      borderRadius: borderRadiusSmall,
                      label: 'Bar Card',
                      onPressed: () async {
                        // Close the popup first, then navigate through Explore → Venue → More Info
                        final root = Navigator.of(context, rootNavigator: true);
                        root.pop(); // dismiss sheet
                        // Give the pop a moment; then chain navigation
                        await Future.delayed(const Duration(milliseconds: 50));
                        root.context.goToExploreVenueBarCard(venue);
                      },
                    ),
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


Widget _tinyIconButton({
  required IconData icon,
  required VoidCallback? onPressed,
  Color color = white,
}) {
  return IconButton(
    onPressed: onPressed,
    icon: Icon(icon, size: iconSizeDefault, color: color),
    padding: EdgeInsets.zero,                                 // no extra padding
    visualDensity: VisualDensity.compact,                     // tighter layout
    splashRadius: 16,                                         // small ripple
    alignment: Alignment.centerRight,
  );
}

Widget _displayOpeningHours(Venue v) {
  final r = v.todayRangeParts24h();
  final supStyle = Styles.smallText;

  return SizedBox(
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        child: Ink(
          decoration: BoxDecoration(
            color: black,
            borderRadius: BorderRadius.circular(borderRadiusSmall),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: r.isClosed || !v.isOpenNow(DateTime.now())
            ? Text('Closed today', style: Styles.smallText.copyWith(color: red))
            : RichText(
              text: TextSpan(
                style: Styles.smallText
                  .copyWith(fontSize: fontSizeSmaller, letterSpacing: 1.5),
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
