import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/utility.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/data/firestore_paths.dart';

LatLng _readLatLng(dynamic v) {
  if (v is GeoPoint) return LatLng(v.latitude, v.longitude);
  if (v is Map) {
    final m = (v as Map).cast<String, dynamic>();
    final lat = (m['lat'] ?? m['latitude']) as num?;
    final lng = (m['lng'] ?? m['longitude']) as num?;
    if (lat != null && lng != null)
      return LatLng(lat.toDouble(), lng.toDouble());
  }
  throw StateError('Invalid LatLng payload: $v');
}

GeoPoint _toGeoPoint(LatLng ll) => GeoPoint(ll.lat, ll.lng);

/// Single source of truth for Venue ↔ Firestore mapping.
class VenueFirestore {
  /// Domain → Firestore (native types)
  static Map<String, Object?> toMap(Venue v) {
    return <String, Object?>{
      // basics
      'name': v.name,
      'display_name': v.displayName,
      'logo_url': v.logoUrl,
      'type': venueTypeToString(v.type),

      // location
      'entry': _toGeoPoint(v.entry),
      'geohash': v.geohash,
      'country_code': v.countryCode,
      'city': v.city,
      'corners': v.corners.map(_toGeoPoint).toList(),

      // metrics
      'rating': v.rating,
      'rating_count': v.ratingCount,
      'like_count': v.likeCount,
      'favorite_count': v.favoriteCount,
      'visit_count': v.visitCount,

      // hours (domain serializer already OK)
      'opening_hours': v.openingHours.toJson(),

      // media
      'cover_image_url': v.coverImageUrl,
      'mood_image_urls': v.moodImageUrls,

      // timestamps
      'created_at':
          v.createdAt == null ? null : Timestamp.fromDate(v.createdAt!),
      'updated_at':
          v.updatedAt == null ? null : Timestamp.fromDate(v.updatedAt!),

      // misc
      'default_entry_price': v.defaultEntryPrice,
      'links': v.links.isEmpty ? null : v.links,
      'email': v.email,
      'phone': v.phone,
      'subscription_type': subscriptionTypeToString(v.subscriptionType),
      'default_age_restriction': v.defaultAgeRestriction,
      'capacity': v.capacity,
      'default_dress_code': dressCodeTypeToString(v.defaultDressCode),
      'is_verified': v.isVerified,
      'primary_color_hex': v.primaryColorHex,
      'secondary_color_hex': v.secondaryColorHex,
      'font_family': v.fontFamily,
      'tag_ids': v.tagids.isEmpty ? null : v.tagids,
      'time_zone_id': v.timeZoneId,
      'description': v.description,
    }..removeWhere((_, v) => v == null);
  }

  /// Firestore snapshot → Domain
  static Venue fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data()!;
    DateTime? _ts(dynamic v) => v is Timestamp ? v.toDate() : null;

    final entry = _readLatLng(data['entry']);
    final cornersRaw = (data['corners'] as List<dynamic>? ?? const []);
    final corners = cornersRaw.map(_readLatLng).toList();

    return Venue(
      id: snap.id,
      name: (data['name'] as String?) ?? '',
      displayName: (data['display_name'] as String?) ??
          Utility.formatString((data['name'] as String?) ?? ''),
      logoUrl: data['logo_url'] as String?,
      type: venueTypeFromString((data['type'] as String?) ?? 'unknown'),
      corners: corners,
      rating: (data['rating'] as num?)?.toDouble(),
      ratingCount: (data['rating_count'] as num?)?.toInt() ?? 0,
      description: (data['description'] as String?) ?? '',
      countryCode: ((data['country_code'] as String?) ?? '').toLowerCase(),
      city: ((data['city'] as String?) ?? '').toLowerCase(),
      likeCount: (data['like_count'] as num?)?.toInt() ?? 0,
      favoriteCount: (data['favorite_count'] as num?)?.toInt() ?? 0,
      visitCount: (data['visit_count'] as num?)?.toInt() ?? 0,
      openingHours: OpeningHours.fromJson(
        (data['opening_hours'] as Map?)?.cast<String, dynamic>(),
      ),
      entry: entry,
      geohash: (data['geohash'] as String?) ?? '',
      defaultAgeRestriction:
          (data['default_age_restriction'] as num?)?.toInt() ?? 18,
      capacity: (data['capacity'] as num?)?.toInt() ?? 100,
      coverImageUrl: data['cover_image_url'] as String?,
      moodImageUrls: (data['mood_image_urls'] as List<dynamic>? ?? const [])
          .cast<String>(),
      timeZoneId: (data['time_zone_id'] as String?),
      createdAt: _ts(data['created_at']),
      updatedAt: _ts(data['updated_at']),
      defaultEntryPrice:
          (data['default_entry_price'] as num?)?.toDouble() ?? 0.0,
      links: (data['links'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          const {},
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      subscriptionType:
          subscriptionTypeFromString(data['subscription_type'] as String?),
      defaultDressCode: dressCodeTypeFromString(
          (data['default_dress_code'] as String?) ?? 'none'),
      isVerified: data['is_verified'] as bool? ?? false,
      primaryColorHex: data['primary_color_hex'] as String?,
      secondaryColorHex: data['secondary_color_hex'] as String?,
      fontFamily: data['font_family'] as String?,
      tagids: (data['tag_ids'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }

  // --- Exact signatures that CollectionReference.withConverter expects -----
  static Venue fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) =>
      fromSnapshot(snap);

  static Map<String, Object?> toFirestore(
    Venue v,
    SetOptions? _,
  ) =>
      toMap(v);
}

/// Centralized typed collection builder.
class VenueCollections {
  VenueCollections({FirebaseFirestore? db})
      : db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore db;

  CollectionReference<Venue> get venues =>
      db.collection(DocumentPaths.venues).withConverter<Venue>(
            fromFirestore: VenueFirestore.fromFirestore,
            toFirestore: VenueFirestore.toFirestore,
          );
}
