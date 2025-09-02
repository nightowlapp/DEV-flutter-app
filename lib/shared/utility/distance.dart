// lib/shared/utility/distance.dart
import 'dart:math' as math;
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

class Distance {
  static const double _earthR = 6371000.0; // meters

  /// Typical walking speed ~1.2 m/s (~4.3 km/h).
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
        math.cos(_deg(lat1)) * math.cos(_deg(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * _earthR * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Haversine distance in **kilometers**.
  static double km(double lat1, double lon1, double lat2, double lon2) =>
      meters(lat1, lon1, lat2, lon2) / 1000.0;

  static double kmLatLng(LatLng a, LatLng b) => metersLatLng(a, b) / 1000.0;

  // -------------------- formatting (Club-style) --------------------
  // Matches your ClubDistanceCalculator._formatDistance behavior.

  /// Format a km value like:
  /// - < 1 km  → "100 m", "150 m", "200 m", ... (rounded to 100/50 steps, min 100)
  /// - 1–10 km → "x.y km" (1 decimal)
  /// - ≥ 10 km → "x km"   (whole number)
  static String formatDistanceClubStyle(double km) {
    if (km.isNaN || km.isInfinite || km < 0) return '—';

    if (km < 1.0) {
      final meters = (km * 1000).ceil();
      final rounded = meters <= 100
          ? 100
          : (meters % 100 <= 50
          ? (meters ~/ 100) * 100 + 50
          : ((meters ~/ 100) + 1) * 100);
      return '$rounded m';
    }
    if (km < 10.0) return km.toStringAsFixed(1) + ' km';
    return km.toStringAsFixed(0) + ' km';
  }

  /// Convenience: format distance between two LatLngs using club style.
  static String formatDistanceClubStyleLatLng(LatLng a, LatLng b) =>
      formatDistanceClubStyle(kmLatLng(a, b));


  // -------------------- extra variants (optional) --------------------

  /// Your older variant: "215 m", "1.2 km", or "99+ km" (cap large numbers).
  static String formatMeters(double? m) {
    if (m == null || m.isNaN) return '—';
    if (m >= 99 * 1000) return '99+ km';
    if (m < 950) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  // -------------------- walking time --------------------
  // Two options: (A) keep your m/s + detour version; (B) club-style fixed 4.2 km/h.

  /// (A) Estimated walking minutes from meters (with detour factor).
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
    if (mins <= 0) return '—';
    if (mins < 60) return '$mins min';
    return '1+ hr';
  }

  /// (B) Club-style walking time using 4.2 km/h and ceil to whole minutes.
  static String walkingTimeTextClubStyleKm(
      double km, {
        double speedKmh = 4.2,
      }) {
    if (km.isNaN || km.isInfinite || km <= 0 || speedKmh <= 0) return '—';
    final totalMinutes = (km / speedKmh * 60).ceil();
    if (totalMinutes < 60) return '$totalMinutes min';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m > 0 ? '$h hr $m min' : '$h hr';
  }

  static String walkingTimeToVenueClubStyle(LatLng? userLoc, Venue venue,
      {double speedKmh = 4.0}) {
    if (userLoc == null) return '';
    final dKm = kmLatLng(userLoc, venue.entry);
    return walkingTimeTextClubStyleKm(dKm, speedKmh: speedKmh);
  }

  // -------------------- legacy wrappers you already use --------------------

  static String distanceText(LatLng? userLoc, Venue venue) {
    if (userLoc == null) return '';
    final double distance = metersLatLng(userLoc, venue.entry);
    if (distance > 99.0)return '99+ km';
    return distance.toString();
  }

  static String walkText(LatLng? userLoc, Venue venue) {
    if (userLoc == null) return '';
    final m = metersLatLng(userLoc, venue.entry);
    return '🚶 ${formatWalkMinutes(m)}';
  }

  static double _deg(double d) => d * math.pi / 180.0;
}
