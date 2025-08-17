import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightowlcode/data/firestore_paths.dart';

import '../../features/map/presentation/geo_hash.dart';

/// Emits **raw GeoJSON** strings (FeatureCollections) for venues & friends.
/// No Mapbox model classes here → easy to test and version-agnostic.
class VenueFriendRepository {
  VenueFriendRepository({
    required this.onVenuesChanged,
    required this.onFriendsChanged,
    this.useFirestore = false, // default: mock mode (no Firebase)
    required this.mock,
  });


  final bool useFirestore;
  final void Function(String geoJson) onVenuesChanged;
  final void Function(String geoJson) onFriendsChanged;


  // Lazy getter; only evaluated if you actually use Firestore.
  FirebaseFirestore get _fs => FirebaseFirestore.instance;
  final bool mock;

  // ---------- State ----------
  final Map<String, Map<String, dynamic>> _venueById = {};
  final Map<String, Map<String, dynamic>> _friendById = {};

  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _venueSubs = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _friendsSub;

  // Requery guards
  String? _lastCenterHash;
  double _lastRadiusKm = 8;
  static const _minMoveMeters = 750.0;

  // Mock timers
  Timer? _friendMockTimer;

  // ---------- Public API ----------
  Future<void> queryVenuesForCamera(double lat, double lng, double zoom, {bool force = false}) async {
    if (mock) {
      // For mock mode, generate many venues around center and emit.
      _seedMockVenues(lat, lng);
      _emitVenues();
      return;
    }

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

    await _startVenuePrefixStreams(lat, lng, rKm, centerHash);
  }

  void startFriendsStream({double? seedLat, double? seedLng}) {
    if (mock) {
      // Mock: seed some friends and jitter them
      _seedMockFriends(seedLat ?? 55.6761, seedLng ?? 12.5683);
      _friendMockTimer?.cancel();
      _friendMockTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _jitterFriends();
        _emitFriends();
      });
      return;
    }

    // _friendsSub?.cancel();
    // final fiveMinAgo = DateTime.now().millisecondsSinceEpoch - 5 * 60 * 1000;
    // _friendsSub = _firestore
    //     .collection('friends_locations')
    //     .where('updatedAt', isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(fiveMinAgo))
    //     .snapshots()
    //     .listen((snap) {
    //   bool changed = false;
    //   for (final d in snap.docs) {
    //     final data = d.data();
    //     final pos = data['position'];
    //     if (pos is! GeoPoint) continue;
    //     final name = (data['name'] ?? '').toString();
    //     _friendById[d.id] = _pointFeature(d.id, pos.latitude, pos.longitude, {
    //       'id': d.id,
    //       'name': name.isEmpty ? 'Friend' : name,
    //     });
    //     changed = true;
    //   }
    //   if (changed) _emitFriends();
    // });
  }

  void dispose() {
    for (final s in _venueSubs) {
      s.cancel();
    }
    _friendsSub?.cancel();
    _friendMockTimer?.cancel();
  }

  // ---------- Firestore venues (clustered source) ----------
  Future<void> _startVenuePrefixStreams(double lat, double lng, double radiusKm, String centerHash) async {
    for (final s in _venueSubs) {
      await s.cancel();
    }
    _venueSubs.clear();

    final precision = centerHash.length;
    final cover = Geohash.coverCircle(lat, lng, radiusKm, precision);
    // final venuesRef = _firestore.collection(DocumentPaths.venues).orderBy('geohash');

    // for (final prefix in cover) {
    //   final sub = venuesRef
    //       .startAt([prefix])
    //       .endAt(['$prefix~'])
    //       .snapshots()
    //       .listen((snap) {
    //     bool changed = false;
    //     for (final doc in snap.docs) {
    //       final data = doc.data();
    //       final gp = data['entry'];
    //       if (gp is! GeoPoint) continue;
    //
    //       final distM = _haversine(lat, lng, gp.latitude, gp.longitude);
    //       if (distM > (radiusKm * 1000 + 200)) continue;
    //
    //       final name = (data['display_name'] ?? data['name'] ?? '').toString();
    //       _venueById[doc.id] = _pointFeature(doc.id, gp.latitude, gp.longitude, {
    //         'id': doc.id,
    //         'name': name,
    //       });
    //       changed = true;
    //     }
    //     if (changed) _emitVenues();
    //   });

      // _venueSubs.add(sub);
    // }
  }

  // ---------- Mock data ----------
  void _seedMockVenues(double lat, double lng) {
    final rnd = math.Random(1);
    _venueById.clear();
    for (int i = 0; i < 600; i++) {
      final dLat = (rnd.nextDouble() - 0.5) * 0.20;
      final dLng = (rnd.nextDouble() - 0.5) * 0.35;
      final id = 'v_$i';
      _venueById[id] = _pointFeature(id, lat + dLat, lng + dLng, {'id': id, 'name': 'Venue #$i'});
    }
  }

  void _seedMockFriends(double lat, double lng) {
    final rnd = math.Random(2);
    _friendById.clear();
    for (int i = 0; i < 6; i++) {
      final dLat = (rnd.nextDouble() - 0.5) * 0.04;
      final dLng = (rnd.nextDouble() - 0.5) * 0.08;
      final id = 'f_$i';
      _friendById[id] = _pointFeature(id, lat + dLat, lng + dLng, {'id': id, 'name': 'Friend ${i + 1}'});
    }
  }

  void _jitterFriends() {
    final rnd = math.Random();
    _friendById.updateAll((id, feat) {
      final coords = (feat['geometry']['coordinates'] as List).cast<num>();
      final lat = coords[1].toDouble() + (rnd.nextDouble() - 0.5) * 0.002;
      final lng = coords[0].toDouble() + (rnd.nextDouble() - 0.5) * 0.004;
      feat['geometry']['coordinates'] = [lng, lat];
      return feat;
    });
  }

  // ---------- Emits ----------
  void _emitVenues() {
    final fc = jsonEncode({'type': 'FeatureCollection', 'features': _venueById.values.toList()});
    onVenuesChanged(fc);
  }

  void _emitFriends() {
    final fc = jsonEncode({'type': 'FeatureCollection', 'features': _friendById.values.toList()});
    onFriendsChanged(fc);
  }

  // ---------- Utils ----------
  Map<String, dynamic> _pointFeature(String id, double lat, double lng, Map<String, dynamic> props) {
    return {
      'type': 'Feature',
      'id': id,
      'properties': props,
      'geometry': {
        'type': 'Point',
        'coordinates': [lng, lat],
      },
    };
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

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) * math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * R * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
