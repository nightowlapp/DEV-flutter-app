import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/distance.dart';

import 'advanced_search_filter.dart';

const double _kDistanceSliderMaxKm = 60.0;

bool venuePassesFilters(
  Venue v,
  AdvancedSearchFilter f, {
  LatLng? userLoc,
  DateTime? nowLocalForVenue,
}) {
  // distance
  if (f.maxDistanceKm != null && userLoc != null) {
    final maxKm = f.maxDistanceKm!;

    // Right-most "60+ km" means "don't filter by distance".
    // Only apply a distance gate when 0 < maxKm < slider max.
    if (maxKm > 0 && maxKm < _kDistanceSliderMaxKm) {
      final meters = Distance.metersLatLng(userLoc, v.entry);
      if (meters > (maxKm * 1000)) return false;
    }
  }

  // rating
  if (f.minRating != null) {
    final r = v.rating ?? 0.0;
    if (r < f.minRating!) return false;
  }

  final now = nowLocalForVenue ?? DateTime.now();

  // open now
  if (f.openNowOnly) {
    if (!v.isOpenNow(now)) return false;
  }

  // verified
  if (f.verifiedOnly && !v.isVerified) return false;

  // age restriction (venue minimum age must be >= requested minAgeRestriction)
  if (f.minAgeRestriction != null) {
    final effAge = v.effectiveAgeRestriction(now);
    if (effAge < f.minAgeRestriction!) return false;
  }

  // entry price
  if (f.maxEntryPrice != null) {
    final price = v.effectiveEntryPrice(now);
    if (price > f.maxEntryPrice!) return false;
  }

  // types
  if (f.types.isNotEmpty && !f.types.contains(v.type)) return false;

  // tags (venue must have at least one of the selected tags)
  if (f.includeTags.isNotEmpty) {
    final hasAny = v.tagids.any((id) => f.includeTags.contains(id));
    if (!hasAny) return false;
  }

  return true;
}
