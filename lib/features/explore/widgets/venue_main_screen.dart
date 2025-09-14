import 'package:flutter/material.dart';
import 'package:nightowlcode/features/explore/widgets/venue_screen_content.dart';
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

import '../../../shared/reusable/ui/verified_badge.dart';


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

  String get _title =>
  venue.displayName.isNotEmpty ? venue.displayName : venue.name;

  @override
  Widget build(BuildContext context) {
    final logo = venueLogo(venue: venue, showInitialFallback: false);
    //TODO below.
    final primaryColor = venue.primaryColorHex ?? owlOrange.toHex();
    final secondaryColor = venue.secondaryColorHex ?? owlOrange.toHex();
    final venueFont = venue.fontFamily ?? Styles.baseFont;

    // titleColor: HexToColor(primaryColor),

    return Scaffold(
      appBar: MainAppBar(
        titleText: _title,
        // verifiedVenue:  true,
        showBack: true,
        centerTitle: true,
        action: logo,
        backgroundColor: black,),
      //TODO looks cool with image at top but dificoult to see name and click back.
      body: CornerBadgeOverlay(
        show: !venue.isVerified,
        badge: VerifiedBadge(), // TODO move to app bar
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: sidePaddingDefault),
          child: VenueScreenContent(
            venue: venue,
            media: media,
            userLoc: userLoc,
          ),
        ),
      ),
    );
  }
}
