// lib/shared/reusable/venues/venue_card.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/distance.dart';

import '../../../data/services/media_existence.dart';
import '../../../shared/utility/custom_network_image.dart';

class VenueCard extends StatelessWidget {
  const VenueCard({
    super.key,
    required this.venue,
    this.userLocation,
    this.media,
    this.fallbackAsset = 'assets/nightowl/logo.png',
    this.onTap,
  });

  final Venue venue;
  final LatLng? userLocation;
  final VenueMediaHealth? media;
  final String fallbackAsset;
  final VoidCallback? onTap;

  TextStyle get _pillStyle =>
      Styles.smallText.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600);

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
    decoration: BoxDecoration(
      color: text.isNotEmpty ?black:transparent,
      borderRadius: BorderRadius.circular(borderRadiusDefault),
    ),
    child: Text(text,
        style: _pillStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
  );

  Widget venueCover(Venue v, VenueMediaHealth? mh) {
    if (mh == null || !mh.coverExists || mh.coverUrl == null) {
      // Show fallback (widget handles it)
      return const CustomNetworkImage('');
    }
    return CustomNetworkImage(mh.coverUrl!);
  }

  @override
  Widget build(BuildContext context) {
    final title = venue.displayName.isNotEmpty ? venue.displayName : venue.name;
    final age = venue.defaultAgeRestriction;
    final isVerified = venue.isVerified;

    // Show walk time or em-dash if unknown
    final String walkText = Distance.walkText(userLocation,venue);

    return Material(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
        child: InkWell(
            onTap: onTap, // ← NEW
            borderRadius: BorderRadius.circular(borderRadiusMedium),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: grey, width: 0.7),
                borderRadius: BorderRadius.circular(borderRadiusMedium),
              ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const AspectRatio(aspectRatio: 0.75, child: SizedBox()),
          Positioned.fill(child: venueCover(venue, media)),
          Positioned(
            top: 2,
            left: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(borderRadiusDefault),
              ),
              child: Center(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          isVerified ?
          Positioned(
              top: -12,
              right: -6,
              child: CircleAvatar( backgroundColor: transparent, child: Icon(checkIcon, color: green, size: iconSizeSmall,),
          )): SizedBox.shrink(),
          Positioned(
            bottom: 2,
            left: 2,
            right: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _pill(walkText),
                _pill('$age+'),
                // _pill(text)
              ],
            ),
          ),
        ],
      ),
    )));
  }
}
