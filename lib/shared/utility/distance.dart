// lib/shared/utility/distance.dart
import 'dart:math' as math;
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

class Distance {
  static const double _earthR = 6371000.0; // meters

  /// Typical walking speed ~1.0 m/s (~3.4 km/h).
  static const double kDefaultWalkMps = 1.0;

  /// Real detour factor for non-straight paths.
  static const double kDefaultDetourFactor = 1.15;

  // -------------------- core distance --------------------

  /// Haversine distance in meters.
  static double metersLatLng(LatLng a, LatLng b) =>
      meters(a.lat, a.lng, b.lat, b.lng);

  static double meters(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _deg(lat2 - lat1);
    final dLon = _deg(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg(lat1)) *
            math.cos(_deg(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * _earthR * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Haversine distance in **kilometers**.
  static double km(double lat1, double lon1, double lat2, double lon2) =>
      meters(lat1, lon1, lat2, lon2) / 1000.0;

  static double kmLatLng(LatLng a, LatLng b) => metersLatLng(a, b) / 1000.0;

  // -------------------- formatting --------------------

  /// Venue distance text:
  /// - < 1.0 km  → show meters (no "0.x km")
  /// - ≥ 1.0 km  → show km with one decimal, but trim trailing .0
  /// - ≥ 99.0 km → "99+ km"
  static String formatVenueDistance(double km) {
    if (km.isNaN || km.isInfinite || km < 0) return '—';

    // < 1 km → meters
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '$meters m';
    }

    // Round to one decimal in tenths to avoid FP issues
    final tenths = (km * 10).round(); // e.g., 12.34 → 123 → 12.3 km
    if (tenths >= 990) return '99+ km';

    // If decimal is zero, show whole number only
    if (tenths % 10 == 0) {
      return '${tenths ~/ 10} km';
    }
    return '${(tenths / 10).toStringAsFixed(1)} km';
  }

  /// Optional helper for raw meters.
  static String formatMeters(double? m) {
    if (m == null || m.isNaN || m.isInfinite) return '—';
    if (m < 1000) return '${m.round()} m';
    // Delegate to venue formatter for km representation
    return formatVenueDistance(m / 1000.0);
  }

  // -------------------- walking time --------------------

  static double walkMinutesFromMeters(
    double meters, {
    double speedMps = kDefaultWalkMps,
    double detourFactor = kDefaultDetourFactor,
  }) {
    if (meters.isNaN || meters.isInfinite || meters <= 0) return 0;
    if (speedMps <= 0) return 0;
    final effectiveMeters = meters * (detourFactor <= 0 ? 1.0 : detourFactor);
    final seconds = effectiveMeters / speedMps;
    return seconds / 60.0;
  }

  static double walkMinutesLatLng(
    LatLng a,
    LatLng b, {
    double speedMps = kDefaultWalkMps,
    double detourFactor = kDefaultDetourFactor,
  }) =>
      walkMinutesFromMeters(
        metersLatLng(a, b),
        speedMps: speedMps,
        detourFactor: detourFactor,
      );

  static int walkMinutesRounded(
    double meters, {
    double speedMps = kDefaultWalkMps,
    double detourFactor = kDefaultDetourFactor,
  }) {
    final m = walkMinutesFromMeters(
      meters,
      speedMps: speedMps,
      detourFactor: detourFactor,
    );
    final r = m.round();
    if (r <= 0 && meters > 0) return 1;
    return r;
  }

  /// Show minutes if < 60.
  /// From 60 min up to < 9 hours show whole-hour values ("1 hr", "2 hr", ...).
  /// At or above 9 hours cap as "9+ hr".
  static String formatWalkMinutes(
    double meters, {
    double speedMps = kDefaultWalkMps,
    double detourFactor = kDefaultDetourFactor,
  }) {
    final mins = walkMinutesRounded(
      meters,
      speedMps: speedMps,
      detourFactor: detourFactor,
    );
    return _formatMinutesAsVenue(mins);
  }

  /// Venue-style walking time from KM (helper if you already have km).
  static String walkingTimeTextVenueKm(
    double km, {
    double speedKmh = 3.4,
  }) {
    if (km.isNaN || km.isInfinite || km <= 0 || speedKmh <= 0) return '—';
    final mins = (km / speedKmh * 60).ceil();
    return _formatMinutesAsVenue(mins);
  }

  /// Walking time to a venue.
  static String walkingTimeToVenue(LatLng? userLoc, Venue venue,
      {double speedKmh = 3.4}) {
    if (userLoc == null) return '';
    final dKm = kmLatLng(userLoc, venue.entry);
    final mins = (dKm / speedKmh * 60).ceil();
    return _formatMinutesAsVenue(mins);
  }

  static String _formatMinutesAsVenue(int mins) {
    if (mins <= 0) return '—';
    if (mins < 60) return '$mins min';
    final hours = mins ~/ 60; // whole numbers
    if (hours >= 9) return '9+ hr';
    return '$hours hr';
  }

  // -------------------- wrappers used around the app --------------------

  /// Distance string for venues: meters below 1 km, else km (one decimal if needed).
  static String distanceText(LatLng? userLoc, Venue venue) {
    if (userLoc == null) return '';
    final dKm = kmLatLng(userLoc, venue.entry);
    return '📍 ${formatVenueDistance(dKm)}';
  }

  static String walkText(LatLng? userLoc, Venue venue) {
    if (userLoc == null) return '';
    final m = metersLatLng(userLoc, venue.entry);
    return '🚶 ${formatWalkMinutes(m)}';
  }

  static double _deg(double d) => d * math.pi / 180.0;
}


class Bounds {
  final double minLat, minLng, maxLat, maxLng;
  const Bounds(this.minLat, this.minLng, this.maxLat, this.maxLng);
  LatLng get center => LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

  static Bounds fromPoints(Iterable<LatLng> pts) {
    final it = pts.iterator;
    if (!it.moveNext()) return const Bounds(0, 0, 0, 0);
    double minLat = it.current.lat, maxLat = it.current.lat;
    double minLng = it.current.lng, maxLng = it.current.lng;
    for (final p in pts) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }
    return Bounds(minLat, minLng, maxLat, maxLng);
  }
}