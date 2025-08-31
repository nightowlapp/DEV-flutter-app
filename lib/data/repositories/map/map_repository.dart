import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'package:nightowlcode/models/users/friend.dart';
import '../../../core/storage/map_storage.dart';
import '../../../features/map/presentation/geo_hash.dart';
import '../../../../models/venues/venue.dart';
import '../../../shared/constants/enums.dart';
import '../../../shared/utility/distance.dart';


class Viewport {
  final double lat, lng, zoom;
  const Viewport(this.lat, this.lng, this.zoom);
}

class VenueFilters {
  final Set<VenueType>? types;     // null => all types
  final String? city;              // already store lowercase
  const VenueFilters({this.types, this.city});

  bool get hasType => (types?.isNotEmpty ?? false);
}

abstract class AbstractVenueRepository {
  Stream<List<Venue>> watchViewport(Viewport vp, {VenueFilters? filters});
}

abstract class AbstractFriendRepository {
  Stream<List<Friend>> watchFriends(Viewport vp);
}

class MapRepository{
  // implements AbstractVenueRepository, AbstractFriendRepository { //TODO
  MapRepository({
    required this.onVenuesChanged,
    required this.onFriendsChanged,
    MapStorage? cache,
    Duration? cacheTtl,
  })  : _cache = cache ?? MapStorage(),
        _cacheTtl = cacheTtl ?? MapStorage.defaultTtl;

  final void Function(String geoJson) onVenuesChanged;
  final void Function(String geoJson) onFriendsChanged;
  final MapStorage _cache;
  final Duration _cacheTtl;

  FirebaseFirestore get _fs => FirebaseFirestore.instance;


  @override
  Stream<List<Venue>> watchViewport(Viewport vp, {VenueFilters? filters}) {
    final out = StreamController<List<Venue>>.broadcast();
    // ... (your existing body, including subs setup and emit())
    out.onCancel = () async {
      for (final s in _venueSubs) { await s.cancel(); }
    };
    return out.stream;  // Add this line
  }

  // @override
  // Future<Stream<List<Friend>>> watchFriends(Viewport vp) async {
  //   // Your existing logic, with real-time snapshots
  //   // ... (from your code, already good)
  // }

  final Map<String, Map<String, dynamic>> _venueById = {};
  final Map<String, Map<String, dynamic>> _friendById = {};
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _venueSubs = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _friendsSub;

  String? _lastCenterHash;
  double _lastRadiusKm = 8;
  static const _minMoveMeters = 750.0;

  Future<void> queryVenuesForCamera(double lat, double lng, double zoom, {bool force = false}) async {
    final position = await Geolocator.getCurrentPosition();
    if (!force && Geolocator.distanceBetween(position.latitude, position.longitude, lat, lng) < 750) return;
    final rKm = _radiusForZoom(zoom);
    final precision = _precisionForRadius(rKm);
    final centerHash = Geohash.encode(lat, lng, precision);
    final movedEnough = (_lastCenterHash == null)
        ? true
        : Geohash.centerDistanceMeters(centerHash, _lastCenterHash!) > _minMoveMeters;
    final radiusChanged = (rKm - _lastRadiusKm).abs() >= 2;
    if (!force && !movedEnough && !radiusChanged) return;
    _lastCenterHash = centerHash;
    _lastRadiusKm = rKm;

    final cover = Geohash.coverCircle(lat, lng, rKm, precision);

    // 1) Cache-first
    await _loadFromCacheThenEmit(precision, cover);

    // 2) Live (SWR)
    await _startVenuePrefixStreams(lat, lng, rKm, precision, cover);
  }

  void startFriendsStream({double? seedLat, double? seedLng}) {
    _friendsSub?.cancel();
    final fiveMinAgo = DateTime.now().millisecondsSinceEpoch - 5 * 60 * 1000;
    _friendsSub = _fs
        .collection('friends_locations')
        .where('updatedAt', isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(fiveMinAgo))
        .snapshots()
        .listen((snap) {
      bool changed = false;
      for (final d in snap.docs) {
        final data = d.data();
        final pos = data['position'];
        if (pos is! GeoPoint) continue;
        final name = (data['name'] ?? '').toString();
        _friendById[d.id] = _pointFeature(d.id, pos.latitude, pos.longitude, {
          'id': d.id,
          'name': name.isEmpty ? 'Friend' : name,
        });
        changed = true;
      }
      if (changed) _emitFriends();
    });
  }

  void dispose() {
    for (final s in _venueSubs) {
      s.cancel();
    }
    _friendsSub?.cancel();
  }

  // -------- Cache helpers
  Future<void> _loadFromCacheThenEmit(int precision, Set<String> cover) async {
    bool loaded = false;
    for (final prefix in cover) {
      final key = _cacheKey(precision, prefix);
      final fc = await _cache.read(key, maxAge: _cacheTtl);
      if (fc == null) {
        continue;
      }
      final feats = (fc['features'] as List).cast<Map<String, dynamic>>();
      for (final f in feats) {
        _venueById[(f['id'] ?? _stableIdFromFeature(f)) as String] = f;
      }
      loaded = true;
    }
    if (loaded) _emitVenues();
  }

  String _cacheKey(int precision, String prefix) => 'v1:$precision:$prefix';

  // -------- Firestore (prefix streams)
  Future<void> _startVenuePrefixStreams(
      double lat,
      double lng,
      double radiusKm,
      int precision,
      Set<String> cover,
      ) async {
    for (final s in _venueSubs) { await s.cancel(); }
    _venueSubs.clear();

    final venuesRef = _fs.collection('venues').orderBy('geohash');
    for (final prefix in cover) {
      final sub = venuesRef
          .startAt([prefix])
          .endAt(['$prefix~'])
          .snapshots()
          .listen((snap) async {
        bool changed = false;
        final perPrefix = <Map<String, dynamic>>[];

        for (final doc in snap.docs) {
          final data = doc.data();
          final gp = data['entry'];
          if (gp is! GeoPoint) continue;

          final distM = Distance.meters(lat, lng, gp.latitude, gp.longitude);
          if (distM > (radiusKm * 1000 + 200)) continue;

          final name = (data['display_name'] ?? data['name'] ?? '').toString();
          final feat = _pointFeature(doc.id, gp.latitude, gp.longitude, {'id': doc.id, 'name': name});

          _venueById[doc.id] = feat;
          perPrefix.add(feat);
          changed = true;
        }

        await _cache.write(_cacheKey(precision, prefix), {
          'type': 'FeatureCollection',
          'features': perPrefix,
        });

        if (changed) _emitVenues();
      });

      _venueSubs.add(sub);
    }
  }

  // -------- Emit + utils
  void _emitVenues() {
    final fc = jsonEncode({'type': 'FeatureCollection', 'features': _venueById.values.toList()});
    onVenuesChanged(fc);
  }

  void _emitFriends() {
    final fc = jsonEncode({'type': 'FeatureCollection', 'features': _friendById.values.toList()});
    onFriendsChanged(fc);
  }

  Map<String, dynamic> _pointFeature(String id, double lat, double lng, Map<String, dynamic> props) => {
    'type': 'Feature', 'id': id, 'properties': props,
    'geometry': {'type': 'Point', 'coordinates': [lng, lat]},
  };

  String _stableIdFromFeature(Map<String, dynamic> f) {
    final c = (f['geometry']?['coordinates'] as List?)?.cast<num>() ?? const [0, 0];
    final n = (f['properties']?['name'] ?? '').toString();
    return '${c[0]}_${c[1]}_$n';
  }

  double _radiusForZoom(double z) {
    if (z >= 16) return 1.2;
    if (z >= 15) return 2;
    if (z >= 13) return 5;
    if (z >= 11) return 8;
    if (z >= 9) return 15;
    return 25;
  }

  int _precisionForRadius(double rKm) {
    if (rKm <= 1.5) return 7;
    if (rKm <= 3) return 6;
    if (rKm <= 8) return 5;
    return 4;
  }


}
