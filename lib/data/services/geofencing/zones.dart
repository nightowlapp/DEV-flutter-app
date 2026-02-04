import 'package:nightowlcode/shared/utility/lat_lng.dart';

import '../../../models/venues/venue.dart';

class VenueZone {
  final String venueId;
  final List<LatLng> polygon; // empty => use circle
  final LatLng center;
  final double radiusM; // used when polygon.isEmpty
  const VenueZone(
      {required this.venueId,
      required this.polygon,
      required this.center,
      this.radiusM = 11});
}

VenueZone zoneFromVenue(Venue v, {double fallbackRadiusM = 11}) {
  final poly = v.corners;
  return VenueZone(
    venueId: v.id,
    polygon: poly,
    center: v.entry,
    radiusM: poly.isEmpty ? fallbackRadiusM : 11,
  );
}