import 'dart:async';
import 'dart:math' as math;
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import '../../../shared/utility/distance.dart';
import 'zones.dart';

class GeofenceEvent {
  final String venueId;
  final bool enter; // true=enter, false=exit
  final DateTime at;
  GeofenceEvent.enter(this.venueId) : enter = true,  at = DateTime.now();
  GeofenceEvent.exit (this.venueId) : enter = false, at = DateTime.now();
} // Best structure? TOdo

class GeofenceEngine {
  GeofenceEngine({
    required Stream<({double lat, double lng})> location$,
    required List<VenueZone> zones,
    this.dwell = const Duration(seconds: 5), // TODo how often? Power drainage?
  }) : _zones = zones {
    _sub = location$.listen(_onLoc);
  }

  final Duration dwell;
  final List<VenueZone> _zones;
  final _out = StreamController<GeofenceEvent>.broadcast();
  StreamSubscription? _sub;

  String? _inside;         // current venueId (if any)
  DateTime? _pendingSince; // dwell timer

  Stream<GeofenceEvent> get events => _out.stream;
  void updateZones(List<VenueZone> zones) => _zones..clear()..addAll(zones);

  void dispose() { _sub?.cancel(); _out.close(); }

  void _onLoc(({double lat, double lng}) p) {
    final now = DateTime.now();
    final next = _resolve(p.lat, p.lng);

    if (next == _inside) {
      _pendingSince = null; // stable
      return;
    }

    // start / check dwell
    _pendingSince ??= now;
    if (now.difference(_pendingSince!) < dwell) return;

    // commit transition
    final prev = _inside;
    _inside = next;
    _pendingSince = null;

    if (prev != null && prev != next) _out.add(GeofenceEvent.exit(prev));
    if (next != null) _out.add(GeofenceEvent.enter(next));
  }

  String? _resolve(double lat, double lng) {
    for (final z in _zones) {
      if (z.polygon.isNotEmpty) {
        if (_pointInPolygon(lat, lng, z.polygon)) return z.venueId;
      } else {
        if (Distance.meters(lat, lng, z.center.lat, z.center.lng) <= z.radiusM) return z.venueId;
      }
    }
    return null;
  }

  // ----- geometry helpers -----
  bool _pointInPolygon(double lat, double lng, List<LatLng> poly) {
    // Ray-casting, works for convex/concave, non-self-intersecting
    bool inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final xi = poly[i].lng, yi = poly[i].lat;
      final xj = poly[j].lng, yj = poly[j].lat;
      final intersect = ((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

}
