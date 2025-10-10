// lib/features/explore/filters/filter_predicate.dart
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/distance.dart';
import 'advanced_search_filter.dart';

bool venuePassesFilters(
  Venue v,
  AdvancedSearchFilter f, {
  LatLng? userLoc,
  DateTime? nowLocalForVenue,
}) {
  // distance
  if (f.maxDistanceKm != null && userLoc != null) {
    final meters = Distance.metersLatLng(userLoc, v.entry);
    if (meters > (f.maxDistanceKm! * 1000)) return false;
  }

  // rating
  if (f.minRating != null) {
    final r = v.rating ?? 0.0;
    if (r < f.minRating!) return false;
  }

  // open now
  if (f.openNowOnly) {
    final now = nowLocalForVenue ?? DateTime.now();
    if (!v.isOpenNow(now)) return false;
  }

  // types
  if (f.types.isNotEmpty && !f.types.contains(v.type)) return false;

  return true;
}
