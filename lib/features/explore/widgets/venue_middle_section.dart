import 'package:flutter/material.dart';
import 'package:nightowlcode/core/platform_config.dart';
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

class VenueMiddleSection extends StatelessWidget {
  const VenueMiddleSection({
    super.key,
    required this.venue,
    this.media,
    this.userLoc,
    this.walkText,               // optional: if you already computed it
    this.isOpen,                 // optional: border color around logo
    this.tags,                   // optional: override tags
    this.rating,                 // optional: show rating card if provided
    this.ratingCount,            // optional: "(123)"
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
  Widget build(BuildContext context) {
    final top = SizedBox(
      height: PlatformConfig.height(context) * 0.25,
      child: OverflowBox(
        alignment: Alignment.center,
        minWidth: 0,
        maxWidth: double.infinity,
        child: SizedBox(
          width: PlatformConfig.width(context), // full screen width
          height: double.infinity,
          child: _cover(), // already BoxFit.cover in your code
        ),
      ),
    );



    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if(_cover() != SizedBox.shrink())top,
        SizedBox(height: PlatformConfig.height(context)*0.02,),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // favoriteButton(),
            // likeButton(),
            Icon(Icons.star, size: iconSizeLarge,),
            SizedBox(width: allSidePaddingDefault,),
            Icon(Icons.heart_broken,size: iconSizeLarge),

            Spacer(),

            Column(
              children: [

                _displayOpeningHours(venue),
                const SizedBox(height: allSidePaddingDefault,),
                _ratingCard(venue),
              ])
          ],
        ),
        SizedBox(height: PlatformConfig.height(context)*0.1,),
        _tagsGrid(venue, context),
        SizedBox(height: PlatformConfig.height(context)*0.1,),

        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,children: [
          Container(
              height: PlatformConfig.height(context)*0.04, width: PlatformConfig.width(context)*0.35,
              child:  OwlButton(borderRadius: borderRadiusSmall,label: 'More Info', onPressed: () => context.pushNamedPage('Home'))),
          // if(venue.isVerified)
          Container(
              height: PlatformConfig.height(context)*0.04, width: PlatformConfig.width(context)*0.35,
              child:  OwlButton(borderRadius: borderRadiusSmall, label: 'Bar Card', onPressed: () => context.pushNamedPage('Home'))),
        ],),
        SizedBox(height: PlatformConfig.height(context)*0.1,),

        if(venue.moodImageUrls.isNotEmpty)
          const Divider(color: white), //TODO mood images



      ],
    );
  }

  Widget _displayOpeningHours(Venue v) {
    final r = v.todayRangeParts24h();
    final baseStyle = Styles.boldText.copyWith(letterSpacing: 1.2,);
    final supStyle  = Styles.smallText.copyWith(fontWeight: FontWeight.w600);

    return SizedBox(
        width: 130,
        child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTapOpeningHours,
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        child: Ink(
          decoration: BoxDecoration(
            color: black, // tweak if you want transparent
            borderRadius: BorderRadius.circular(borderRadiusSmall),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          // constraints: const BoxConstraints(minWidth: 100),
          child: r.isClosed
              ? Text('Closed today', style: baseStyle)
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
                      offset: const Offset(2, -5), // superscript look
                      child: Text('+1', style: supStyle),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _cover() {
    final hasCover = media != null && media!.coverExists && (media!.coverUrl?.isNotEmpty ?? false);
    return CustomNetworkImage(
      hasCover ? media!.coverUrl! : '',
      fit: BoxFit.cover, // fill width
      fallBackEnabled: false,
    );
  }
  Widget _ratingCard(Venue v) {
    final hasRating = v.rating != null;
    final r = v.rating ?? 0.0;
    final countText = v.ratingCount > 0 ? '(${_formatRatingCount(v.ratingCount)})' : '(0)';

    return SizedBox(
      width: 130,
      child: Material(
        color: black,
        child: Ink(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // numeric badge
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    color: black,
                    border: Border.all(color: owlOrange, width: 2),
                    borderRadius: BorderRadius.circular(borderRadiusSmall),
                  ),
                  child: Text(
                    hasRating ? r.toStringAsFixed(1) : '—',
                    style: Styles.boldText,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) {
                          final idx = i + 1;
                          final filled = r >= idx;
                          final half = r >= (idx - 0.5) && r < idx;
                          return Icon(
                            filled
                                ? filledStarIcon
                                : (half ? halfFilledStarIcon : emptyStarIcon),
                            color: owlOrange,
                            size: 14, // keep visuals same as opening-hours chip
                          );
                        }),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        countText,
                        style: Styles.smallText.copyWith(fontSize: 9, color: white.withOpacity(0.9)),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRatingCount(int n) {
    if (n >= 1000000) {
      final d = n / 1000000;
      return d >= 10 ? '${d.toStringAsFixed(0)}M' : '${d.toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      final d = n / 1000;
      return d >= 10 ? '${d.toStringAsFixed(0)}k' : '${d.toStringAsFixed(1)}k';
    }
    return n.toString();
  }
  Widget _tagsGrid(Venue v, BuildContext context) {
    final sorted = List.of(v.tagids)..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (sorted.isEmpty) return const SizedBox.shrink();

    // layout constants (3 rows, horizontal scroll, fixed height)
    const rows = 2;
    const vPad = 8.0;                // equal top/bottom padding
    const hPad = 8.0;
    final tagWidth  = PlatformConfig.width(context) *0.35;
    const mainAxisSpacing = 10.0;    // horizontal spacing between items
    const crossAxisSpacing = 5.0;    // vertical spacing between rows
    const childAspectRatio = 5.0;    // width / height (wide pill)
    const chipHeight = 28.0;         // per-row item height

    return SizedBox(
      height: PlatformConfig.height(context)*0.1,
      child: Container(
        decoration: BoxDecoration(
          color: black,
          border: Border.all(color: white, width: 1.5),
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
        padding: const EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
        child: GridView.builder(
          scrollDirection: Axis.horizontal, // ← sideways
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: sorted.length,
          gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: rows,                 // rows when scrolling horizontally
            crossAxisSpacing: crossAxisSpacing,   // vertical gap between rows
            mainAxisSpacing: mainAxisSpacing,     // horizontal gap
            childAspectRatio: childAspectRatio,   // width / height
            mainAxisExtent: tagWidth,
          ),
          itemBuilder: (context, index) {
            final tag = sorted[index];
            return SizedBox(
              height: chipHeight,                 // lock row height
              child: _neonTagChip(tag, owlOrange),
            );
          },
        ),
      ),
    );
  }

  Widget _neonTagChip(String tag, Color c) {
    return Container(
      decoration: BoxDecoration(
        color: black,
        borderRadius: BorderRadius.circular(borderRadiusSmallest),
        border: Border.all(color: c, width: 1),
        boxShadow: [
          BoxShadow(color: c.withOpacity(0.45), blurRadius: 10, spreadRadius: 1),
          BoxShadow(color: c.withOpacity(0.20), blurRadius: 2, spreadRadius: 0.5),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        children: [
          // left icon badge
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: c.withOpacity(0.10),
              borderRadius: BorderRadius.circular(borderRadiusSmallest),
              border: Border.all(color: c, width: 1),
            ),
            alignment: Alignment.center,
            // child: Icon(_iconForTag(tag), size: 14, color: white),
          ),
          const SizedBox(width: 5),
          // label
          Expanded(
            child: Text(
              tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Styles.boldText.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

}
