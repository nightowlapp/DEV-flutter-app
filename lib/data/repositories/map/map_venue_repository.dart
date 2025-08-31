// lib/features/map/data/map_venue_repository.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/features/map/presentation/geo_hash.dart';

import 'map_repository.dart';


class FirestoreMapVenueRepository implements AbstractVenueRepository {
  FirestoreMapVenueRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  @override
  Stream<List<Venue>> watchViewport(Viewport vp, {VenueFilters? filters}) {
    final out = StreamController<List<Venue>>.broadcast();
    final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    final venues = <String, Venue>{};

    void emit() => out.add(venues.values.toList());

    final rKm = _radiusForZoom(vp.zoom);
    final precision = _precisionForRadius(rKm);
    final cover = Geohash.coverCircle(vp.lat, vp.lng, rKm, precision);

    for (final prefix in cover) {
      final sub = _db.collection('venues')
          .orderBy('geohash')
          .startAt([prefix])
          .endAt(['$prefix~'])
          .snapshots()
          .listen((snap) {
        bool changed = false;
        for (final doc in snap.docs) {
          final data = doc.data();
          final gp = data['entry'];
          if (gp is! GeoPoint) continue;

          final distM = _haversine(vp.lat, vp.lng, gp.latitude, gp.longitude);
          if (distM > (rKm * 1000 + 200)) continue;

          final v = Venue(
            id: doc.id,
            name: (data['name'] ?? '') as String,
            displayName: ((data['display_name'] ?? data['name']) as String?) ?? '',
            type: _safeVenueType(data['type'] as String?),
            entry: LatLng(gp.latitude, gp.longitude),
            geohash: (data['geohash'] ?? '') as String,
            countryCode: ((data['country_code'] ?? 'xx') as String).toLowerCase(),
            city: ((data['city'] ?? '') as String).toLowerCase(),
            openingHours: OpeningHours(week: List.filled(7, const DaySchedule(openMinutes: null, closeMinutes: null))),
            corners: const [],
            rating: (data['rating'] as num?)?.toDouble(),
            subscriptionType: _safeSubType(data['subscription_type'] as String?),
            isVerified: (data['is_verified'] as bool?) ?? false,
            defaultDressCode: DressCodeType.none,
            tagids: const [],
          );

          venues[v.id] = v;
          changed = true;
        }
        if (changed) emit();
      });
      subs.add(sub);
    }

    out.onCancel = () async {
      for (final s in subs) { await s.cancel(); }
    };
    return out.stream;
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

  VenueType _safeVenueType(String? s) {
    final v = (s ?? '').trim().toLowerCase();
    return VenueType.values.firstWhere((e) => e.name == v, orElse: () => VenueType.unknown);
  }

  SubscriptionTypesVenue _safeSubType(String? s) {
    final v = (s ?? '').trim().toLowerCase();
    return SubscriptionTypesVenue.values.firstWhere((e) => e.name == v, orElse: () => SubscriptionTypesVenue.free);
  }
}
