import 'package:flutter/material.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/models/venues/venue.dart';
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

  String get _title => venue.displayName.isNotEmpty ? venue.displayName : venue.name;

  @override
  Widget build(BuildContext context) {
    final String walk = walkText ?? _computeWalk(userLoc, venue.entry);
    final String ageText = '${venue.defaultAgeRestriction}+';
    final List<String> _tags =
      (_resolveTags() ?? const[]).where((t) => t.trim().isNotEmpty).toList();
    final double _ratingValue = rating ?? 0.0;      // show rating even if null
    final String _ratingCountText = ratingCount?.isNotEmpty == true ? ratingCount! : '(0)';

    // ---------- Top: cover image + overlapping row (name + logo) ----------
    // 1) Replace your `top` with this:
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

    // ---------- Middle: opening hours + age, rating ----------
    final middle = Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
      // favoriteButton(),
      // likeButton(),
              Icon(Icons.star),
              Icon(Icons.heart_broken),
Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onTapOpeningHours,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      decoration: BoxDecoration(
                      // borderRadius: BorderRadius.circular(8),
                      // border: Border.all(color: white),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _openingHours(venue),
                            style: const TextStyle(fontSize: 13, color: white),
                          ),
                          const SizedBox(width: 10),
                          Text(ageText, style: const TextStyle(fontSize: 13, color: white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (rating != null) _ratingCard(rating!),
                  if (ratingCount != null && ratingCount!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        ratingCount!,
                        style: const TextStyle(color: white, fontSize: 10),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Tags grid (optional)
          if ((_resolveTags() ?? const[]).isNotEmpty)
          _tagsGrid(_resolveTags()!, context),

          if ((_resolveTags() ?? const[]).isNotEmpty) const SizedBox(height: 32),

          // Actions row
          Row(
            mainAxisAlignment: hasBarCard ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center,
            children: [
              OwlButton(label: 'More Info', onPressed: () { onTapMoreInfo;
                },),
              if (hasBarCard)
              OwlButton(label: 'Bar Card', onPressed: () { onTapBarCard;
                },),
            ],
          ),
        ],
      ),
    );

    // ---------- Additional content example (offer / stats / mood) ----------
    final extras = Column(
      children: [
        const SizedBox(height: 20),
        if (walk.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: sidePaddingDefault),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _pill(walk),
          ),
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if(_cover() != SizedBox.shrink())top,

        middle,
        extras,
      ],
    );
  }

  Widget _cover() {
    final hasCover = media != null && media!.coverExists && (media!.coverUrl?.isNotEmpty ?? false);
    return CustomNetworkImage(
      hasCover ? media!.coverUrl! : '',
      fit: BoxFit.cover, // fill width
      fallBackEnabled: false,
    );
  }

  Widget _chipIcon({required IconData icon, required String label, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: owlOrange),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: white),
            ),
            child: Text(
              label,
              style: const TextStyle(color: white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingCard(double rating) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: grey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: white,
              border: Border.all(color: owlOrange, width: 3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                color: black,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Row(
            textDirection: TextDirection.rtl,
            children: List.generate(5, (i) {
                if (rating >= i + 1) return const Icon(Icons.star, color: owlOrange, size: 14);
                if (rating > i) return const Icon(Icons.star_half, color: owlOrange, size: 14);
                return const Icon(Icons.star_border, color: owlOrange, size: 14);
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagsGrid(List<String> tags, BuildContext context) {
    final sorted = List.of(tags);
    sorted.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: white, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      constraints: const BoxConstraints(maxHeight: 105),
      child: GridView.builder(
        itemCount: sorted.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 6,
          mainAxisSpacing: 16,
          childAspectRatio: 3.0,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final tag = sorted[index];
          return Container(
            decoration: BoxDecoration(
              color: black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: owlOrange, width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Center(
              child: Text(
                tag,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }

// Replace your _openingHours with this:
  String _openingHours(Venue venue) {
    final OpeningHours? oh = venue.openingHours;
    if (oh == null) return 'Hours unavailable';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Pick exception for today (if any), otherwise today schedule from week[]
    final exception = oh.exceptions.firstWhere(
          (e) => e.date == today,
      orElse: () => ExceptionHours(date: DateTime(1970, 1, 1)),
    );

    final DaySchedule schedule = (exception.date == today)
        ? DaySchedule(
      isClosed: exception.isClosed,
      openMinutes: exception.openMinutes,
      closeMinutes: exception.closeMinutes,
      ageRestriction: exception.ageRestriction,
      dressCode: exception.dressCode,
      entryPrice: exception.entryPrice,
    )
        : oh.week[(now.weekday - 1) % 7];

    if (schedule.isClosed || schedule.openMinutes == null || schedule.closeMinutes == null) {
      return 'Closed today';
    }

    String _fmt(int minutes) {
      final h = (minutes ~/ 60) % 24;
      final m = minutes % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }

    return '${_fmt(schedule.openMinutes!)}–${_fmt(schedule.closeMinutes!)}';
  }

  String _computeWalk(LatLng? user, LatLng dest) {
    if (user == null) return '';
    final meters = Distance.metersLatLng(user, dest);
    return '🚶 ${Distance.formatWalkMinutes(meters)}';
  }

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
    decoration: BoxDecoration(
      color: black,
      border: Border.all(color: grey, width: 0.7),
      borderRadius: BorderRadius.circular(borderRadiusDefault),
    ),
    child: Text(
      text,
      style: Styles.smallText.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );

  List<String>? _resolveTags() {
    if (tags != null) return tags;
    try {
      final dynamic v = venue;
      final raw = (v as dynamic).tags as List<dynamic>?;
      return raw?.whereType<String>().toList();
    }
    catch (_) {
      return null;
    }
  }
}
