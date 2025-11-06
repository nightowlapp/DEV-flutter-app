// lib/features/venues/data/venue_cache.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/providers/other_providers.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/distance.dart';
import 'package:nightowlcode/core/storage/venues_sso.dart'; // venuesListProvider

class VenueCache {
  final List<Venue> _all;
  final Map<String, Venue> _byId;

  VenueCache._(this._all, this._byId);

  factory VenueCache.fromList(List<Venue> list) =>
      VenueCache._(List.unmodifiable(list),
          Map<String, Venue>.unmodifiable({for (final v in list) v.id: v}));

  // ---- lookups ----
  List<Venue> get all => _all;
  int get size => _all.length;
  Venue? get(String id) => _byId[id];
  bool contains(String id) => _byId.containsKey(id);

  /// Fast linear nearest (good up to a few 10k venues). Swap with grid later.
  String? nearest(LatLng p, {double maxMeters = 50}) {
    String? bestId;
    double best = maxMeters;
    for (final v in _all) {
      final d = Distance.metersLatLng(p, v.entry);
      if (d < best) { best = d; bestId = v.id; }
    }
    return bestId;
  }

  /// Simple viewport filtering (optional helper)
  Iterable<Venue> withinBounds({
    required double minLat, required double minLng,
    required double maxLat, required double maxLng,
  }) sync* {
    for (final v in _all) {
      final lat = v.entry.lat, lng = v.entry.lng;
      if (lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng) {
        yield v;
      }
    }
  }
}
