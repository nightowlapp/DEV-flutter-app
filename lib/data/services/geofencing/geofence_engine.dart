// lib/data/services/geofencing/geofence_engine.dart
import 'dart:async';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/distance.dart';
import 'zones.dart';

class GeofenceEvent {
  final String venueId;
  final bool enter; // true=enter, false=exit
  final DateTime at;
  GeofenceEvent.enter(this.venueId)
      : enter = true,
        at = DateTime.now();
  GeofenceEvent.exit(this.venueId)
      : enter = false,
        at = DateTime.now();
}

class GeofenceEngine {
  GeofenceEngine({
    required Stream<({double lat, double lng})> location$,
    required List<VenueZone> zones,
    this.dwell = const Duration(seconds: 5),
  }) : _zones = zones {
    _sub = location$.listen(
      _onLoc,
      onError: (_, __) {}, // keep engine alive on errors
      cancelOnError: false,
    );
  }

  final Duration dwell;
  final List<VenueZone> _zones;
  final _out = StreamController<GeofenceEvent>.broadcast();
  StreamSubscription? _sub;

  // committed state
  String? _inside; // current committed venueId (or null)
  ({double lat, double lng})? _lastPoint; // last known point

  // dwell state
  String? _candidate; // pending target venueId (or null meaning "outside")
  Timer? _dwellTimer;

  Stream<GeofenceEvent> get events => _out.stream;

  void updateZones(List<VenueZone> zones) {
    final prevInside = _inside;
    _zones
      ..clear()
      ..addAll(zones);

    // If we were inside a zone that disappeared → exit immediately.
    if (prevInside != null && !_zones.any((z) => z.venueId == prevInside)) {
      _cancelDwell();
      _inside = null;
      _out.add(GeofenceEvent.exit(prevInside));
    }

    // If we’re dwelling towards a zone that disappeared → cancel dwell.
    if (_candidate != null && !_zones.any((z) => z.venueId == _candidate)) {
      _cancelDwell();
      _candidate = null;
    }
  }

  void dispose() {
    _sub?.cancel();
    _cancelDwell();
    _out.close();
  }

  void _onLoc(({double lat, double lng}) p) {
    _lastPoint = p;
    final next = _resolve(p.lat, p.lng);

    if (next == _inside) {
      // stable → cancel any dwell
      _cancelDwell();
      _candidate = null;
      return;
    }

    // schedule dwell towards `next`
    _scheduleDwell(next);
  }

  void _scheduleDwell(String? next) {
    _candidate = next;
    _dwellTimer?.cancel();
    _dwellTimer = Timer(dwell, () {
      // Re-resolve with last point (zones may have changed)
      final p = _lastPoint;
      final still = (p == null) ? null : _resolve(p.lat, p.lng);
      if (still != _candidate) return; // state changed during dwell
      _commitTransition(still);
    });
  }

  void _commitTransition(String? next) {
    final prev = _inside;
    _inside = next;
    _cancelDwell();
    _candidate = null;

    if (prev != null && prev != next) _out.add(GeofenceEvent.exit(prev));
    if (next != null) _out.add(GeofenceEvent.enter(next));
  }

  void _cancelDwell() {
    _dwellTimer?.cancel();
    _dwellTimer = null;
  }

  String? _resolve(double lat, double lng) {
    for (final z in _zones) {
      if (z.polygon.isNotEmpty) {
        if (_pointInPolygon(lat, lng, z.polygon)) return z.venueId;
      } else {
        if (Distance.meters(lat, lng, z.center.lat, z.center.lng) <=
            z.radiusM) {
          return z.venueId;
        }
      }
    }
    return null;
  }

  // Ray-casting point-in-polygon
  bool _pointInPolygon(double lat, double lng, List<LatLng> poly) {
    bool inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final xi = poly[i].lng, yi = poly[i].lat;
      final xj = poly[j].lng, yj = poly[j].lat;
      final intersect = ((yi > lat) != (yj > lat)) &&
          (lng <
              (xj - xi) * (lat - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) +
                  xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }
}
