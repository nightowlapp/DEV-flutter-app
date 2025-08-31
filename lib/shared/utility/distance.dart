// lib/shared/utility/distance.dart
import 'dart:math' as math;
import 'package:nightowlcode/shared/utility/lat_lng.dart';

class Distance {
  static const double _earthR = 6371000.0; // meters

  /// Typical walking speed ~1.4 m/s (~5 km/h).
  static const double kDefaultWalkMps = 1.2;

  /// Real-world detour factor to account for streets/obstacles
  /// (1.0 = straight line, 1.15 = +15%).
  static const double kDefaultDetourFactor = 1.15;

  // -------------------- distances --------------------

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

  /// "215 m", "1.2 km", or "99+ km" (cap large numbers).
  static String formatMeters(double? m) {
    if (m == null || m.isNaN) return '—';
    if (m >= 99 * 1000) return '99+ km'; // cap at 99+ km
    if (m < 950) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  // -------------------- walking time --------------------

  /// Estimated walking minutes from meters.
  ///
  /// [speedMps] sets walking speed (default ~1.4 m/s).
  /// [detourFactor] inflates the straight-line distance for real paths.
  /// Returns fractional minutes (e.g., 6.4).
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

  /// Estimated walking minutes between two points.
  static double walkMinutesLatLng(
      LatLng a,
      LatLng b, {
        double speedMps = kDefaultWalkMps,
        double detourFactor = kDefaultDetourFactor,
      }) {
    return walkMinutesFromMeters(
      metersLatLng(a, b),
      speedMps: speedMps,
      detourFactor: detourFactor,
    );
  }

  /// Rounded walking minutes (minimum 1 if distance > 0).
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

  /// Human-friendly walking time.
  /// Shows minutes up to 59; at 60+ shows "1+ hr".
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

  static double _deg(double d) => d * math.pi / 180.0;
}
