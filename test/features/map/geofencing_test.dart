import 'dart:math';

enum GeoEvent { enter, exit, dwell, none }

class SoftwareGeofence {
  SoftwareGeofence({
    required this.centerLat,
    required this.centerLng,
    required this.radiusMeters,
    this.dwellMillis = 300000, // 5 min
  });

  final double centerLat;
  final double centerLng;
  final double radiusMeters;
  final int dwellMillis;

  bool _inside = false;
  int? _enteredAt;

  // Haversine distance (m)
  static double _distance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double d) => d * pi / 180.0;

  /// Feed timestamped points (e.g., from a GPX player) and get events.
  GeoEvent onLocation(double lat, double lng, int timestampMillis) {
    final d = _distance(centerLat, centerLng, lat, lng);
    final nowInside = d <= radiusMeters;

    if (!(_inside) && nowInside) {
      _inside = true;
      _enteredAt = timestampMillis;
      return GeoEvent.enter;
    }
    if (_inside && !nowInside) {
      _inside = false;
      _enteredAt = null;
      return GeoEvent.exit;
    }
    if (_inside && _enteredAt != null &&
        (timestampMillis - _enteredAt!) >= dwellMillis) {
      // Fire dwell once, then reset so it won't spam.
      _enteredAt = null;
      return GeoEvent.dwell;
    }
    return GeoEvent.none;
  }
}
