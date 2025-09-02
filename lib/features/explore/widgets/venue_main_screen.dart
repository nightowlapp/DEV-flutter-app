import 'package:flutter/material.dart';
import 'package:nightowlcode/features/main/widgets/main_app_bar.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/reusable/ui/venue_logo.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/distance.dart';
import 'package:nightowlcode/data/services/media_existence.dart';

import 'venue_middle_section.dart';

class VenueMainScreen extends StatelessWidget {
  const VenueMainScreen({
    super.key,
    required this.venue,
    this.media,
    this.userLoc,
  });

  final Venue venue;
  final VenueMediaHealth? media;
  final LatLng? userLoc;

  String get _title => venue.displayName.isNotEmpty ? venue.displayName : venue.name;

  @override
  Widget build(BuildContext context) {
    final double? meters =
    (userLoc == null) ? null : Distance.metersLatLng(userLoc!, venue.entry);
    final String walkText = (meters == null) ? '' : '🚶 ${Distance.formatWalkMinutes(meters)}';

    final logo = venueLogo(venue: venue,    );
    // final primaryColor = venue.primaryColorHex!;
    // titleColor: HexToColor(primaryColor),
    return Scaffold(
      appBar: MainAppBar(titleText: _title,  showBack: true, centerTitle: true, action: logo, backgroundColor: black,), //TODO looks cool with image at top but dificoult to see name and click back.
      body: Stack(
        children: [
          // ---------- Main content (unchanged layout) ----------
          // ---------- Main content (replace this block only) ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: sidePaddingDefault),
            child: VenueMiddleSection(
              venue: venue,
              media: media,
              userLoc: userLoc,
              // optional extras you can pass now or later:
              // rating: 4.5,
              // ratingCount: '(128)',
              // isOpen: true,
              // tags: const ['Hip Hop', 'Dance', 'Rooftop', 'Cocktails'],
              // onTapOpeningHours: () {},
              // onTapMoreInfo: () {},
              // onTapBarCard: () {},
              // hasBarCard: true,
            ),
          ),


          // ---------- Verified overlay (independent, never interferes) ----------
          if (venue.isVerified)
            Positioned(
              right: 0,
              child: SafeArea(
                top: true,
                child: IgnorePointer( // overlay but doesn't block touches
                  ignoring: true,
                  child: _VerifiedBadge(),
                ),
              ),
            ),
        ],
      ),
    );
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
}

/// Small, centered icon+label badge.
class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0,), // tiny background
      decoration: BoxDecoration(
        color: black,
        borderRadius: BorderRadius.circular(borderRadiusDefault),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(checkCircleIcon, color: green, size: iconSizeMedium),
          Text(
            'Verified',
            textAlign: TextAlign.center,
            style: Styles.smallText.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
