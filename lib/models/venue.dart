// lib/models/venue.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:nightowlcode/shared/constants/enums.dart'; // VenueType enum with .unknown
import 'package:nightowlcode/shared/utility.dart'; // Utility + JsonUtility helpers

// ---------- Enum (de)serializers ----------
VenueType venueTypeFromString(String s) => VenueType.values.firstWhere(
      (e) => describeEnum(e).toLowerCase() == (s.trim().toLowerCase()),
  orElse: () => VenueType.unknown,
);

String venueTypeToString(VenueType t) => describeEnum(t);

enum SubscriptionTypeClub { free, trial, premium }

SubscriptionTypeClub subscriptionTypeFromString(String? s) {
  final v = (s ?? '').trim().toLowerCase();
  return SubscriptionTypeClub.values.firstWhere(
        (e) => describeEnum(e) == v,
    orElse: () => SubscriptionTypeClub.free,
  );
}

String subscriptionTypeToString(SubscriptionTypeClub t) => describeEnum(t);

// ---------- Minutes helper ----------
int _toMinutes(int hour, int minute) => (hour * 60) + minute;

// ---------- DaySchedule ----------
@immutable
class DaySchedule {
  final int? openMinutes; // null => closed
  final int? closeMinutes; // null => closed
  final int? ageRestriction; // per-day override

  const DaySchedule({
    required this.openMinutes,
    required this.closeMinutes,
    this.ageRestriction,
  });

  bool get isClosed => openMinutes == null || closeMinutes == null;

  Map<String, dynamic> toJson() => {
    'open': openMinutes,
    'close': closeMinutes,
    if (ageRestriction != null) 'age_restriction': ageRestriction,
  };

  factory DaySchedule.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const DaySchedule(openMinutes: null, closeMinutes: null);
    }
    return DaySchedule(
      openMinutes: JsonUtility.asNum<int>(json['open'], (n) => n.toInt()),
      closeMinutes: JsonUtility.asNum<int>(json['close'], (n) => n.toInt()),
      ageRestriction:
      JsonUtility.asNum<int>(json['age_restriction'], (n) => n.toInt()),
    );
  }

  DaySchedule copyWith({
    int? openMinutes,
    int? closeMinutes,
    int? ageRestriction,
    bool clearAgeRestriction = false,
  }) {
    return DaySchedule(
      openMinutes: openMinutes ?? this.openMinutes,
      closeMinutes: closeMinutes ?? this.closeMinutes,
      ageRestriction:
      clearAgeRestriction ? null : (ageRestriction ?? this.ageRestriction),
    );
  }
}

// ---------- ExceptionHours ----------
@immutable
class ExceptionHours {
  final DateTime date; // local date (00:00)
  final int? openMinutes;
  final int? closeMinutes;
  final int? ageRestriction;

  const ExceptionHours({
    required this.date,
    this.openMinutes,
    this.closeMinutes,
    this.ageRestriction,
  });

  bool get isClosed => openMinutes == null || closeMinutes == null;

  Map<String, dynamic> toJson() => {
    'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
    'open': openMinutes,
    'close': closeMinutes,
    if (ageRestriction != null) 'age_restriction': ageRestriction,
  };

  factory ExceptionHours.fromJson(Map<String, dynamic> json) {
    final ts = json['date'] as Timestamp;
    final d = ts.toDate();
    final onlyDate = DateTime(d.year, d.month, d.day);
    return ExceptionHours(
      date: onlyDate,
      openMinutes: JsonUtility.asNum<int>(json['open'], (n) => n.toInt()),
      closeMinutes: JsonUtility.asNum<int>(json['close'], (n) => n.toInt()),
      ageRestriction:
      JsonUtility.asNum<int>(json['age_restriction'], (n) => n.toInt()),
    );
  }
}

// ---------- OpeningHours ----------
@immutable
class OpeningHours {
  /// 0=Mon ... 6=Sun
  final List<DaySchedule> week; // length 7
  final List<ExceptionHours> exceptions;

  const OpeningHours({
    required this.week,
    this.exceptions = const [],
  }) : assert(week.length == 7, 'week must have 7 entries (Mon..Sun)');

  Map<String, dynamic> toJson() => {
    'week': week.map((d) => d.toJson()).toList(),
    if (exceptions.isNotEmpty)
      'exceptions': exceptions.map((e) => e.toJson()).toList(),
  };

  factory OpeningHours.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return OpeningHours(
        week: List.generate(
          7,
              (_) => const DaySchedule(openMinutes: null, closeMinutes: null),
        ),
      );
    }
    final weekJson = (json['week'] as List<dynamic>?) ?? const [];
    final week = List<DaySchedule>.generate(
      7,
          (i) => i < weekJson.length
          ? DaySchedule.fromJson(weekJson[i] as Map<String, dynamic>?)
          : const DaySchedule(openMinutes: null, closeMinutes: null),
    );
    final exceptionsJson =
        (json['exceptions'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            const [];
    return OpeningHours(
      week: week,
      exceptions: exceptionsJson.map(ExceptionHours.fromJson).toList(),
    );
  }

  bool isOpenAt(DateTime localNow) {
    final minutes = localNow.hour * 60 + localNow.minute;
    final today = DateTime(localNow.year, localNow.month, localNow.day);

    final exception = exceptions.firstWhere(
          (e) => e.date == today,
      orElse: () => ExceptionHours(date: DateTime(1970, 1, 1)),
    );

    final DaySchedule schedule = (exception.date == today)
        ? DaySchedule(
      openMinutes: exception.openMinutes,
      closeMinutes: exception.closeMinutes,
      ageRestriction: exception.ageRestriction,
    )
        : week[(localNow.weekday - 1) % 7];

    if (schedule.isClosed) return false;

    final open = schedule.openMinutes!;
    final close = schedule.closeMinutes!;
    if (open == close) return false;

    if (close > open) {
      return minutes >= open && minutes < close;
    } else {
      // overnight (e.g. 22:00-03:00)
      return minutes >= open || minutes < close;
    }
  }

  int? activeAgeRestriction(DateTime localNow) {
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final exception = exceptions.firstWhere(
          (e) => e.date == today,
      orElse: () => ExceptionHours(date: DateTime(1970, 1, 1)),
    );
    if (exception.date == today) return exception.ageRestriction;
    return week[(localNow.weekday - 1) % 7].ageRestriction;
  }
}

// ---------- Venue ----------
@immutable
class Venue {
  final String id; // REQUIRED

  // Basics
  final String name; // slug/technical REQUIRED
  final String displayName; // marketing REQUIRED
  final VenueType type; // REQUIRED
  final GeoPoint entry; // map pin REQUIRED
  final String geohash; // required by doc (computed elsewhere)
  final String countryCode; // ISO-3166 alpha-2 (lowercase) REQUIRED
  final String city; // REQUIRED

  // Auditing
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  // ---------- Media ----------
  final String? logoUrl;
  final String? coverImageUrl;
  final List<String> moodImageUrls;

  // ---------- Identity & Description ----------
  final String description;
  final String? timeZoneId; // IANA, optional

  final OpeningHours openingHours;
  final SubscriptionTypeClub subscriptionType;

  final int defaultAgeRestriction;
  final int capacity;

  final List<GeoPoint> corners;
  final List<String> tags; // doc

  // ---------- Aggregates / Metrics ----------
  // Doc uses `rating` (double). Keep your fields but serialize to `rating`.
  final double? rating;
  final int? defaultEntryPrice; // doc: entry_price (unknown valuta)
  final int ratingCount;
  final int likeCount;
  final int favoriteCount;
  final int visitCount;

  // ---------- Extra Fields ----------
  final String? dressCode; // doc
  final Map<String, String> links;
  final String? email; // doc
  final String? phone; // doc

  const Venue({
    required this.id,
    required this.name,
    required this.displayName,
    required this.type,
    required this.corners,
    required this.ratingCount,
    required this.description,
    required this.countryCode,
    required this.city,
    required this.likeCount,
    required this.favoriteCount,
    required this.visitCount,
    required this.openingHours,
    required this.entry,
    required this.geohash,
    required this.defaultAgeRestriction,
    required this.capacity,
    this.logoUrl,
    this.rating,
    this.coverImageUrl,
    this.moodImageUrls = const [],
    this.timeZoneId,
    this.createdAt,
    this.updatedAt,
    this.defaultEntryPrice,
    this.links = const {},
    this.email,
    this.phone,
    this.subscriptionType = SubscriptionTypeClub.free,
    this.dressCode,
    this.tags = const [],
  });

  // ---------- (de)serialization: Firestore snake_case ----------
  factory Venue.fromJson(Map<String, dynamic> json, String id) {
    String _readString(dynamic v, {String? fallback}) =>
        JsonUtility.nullIfEmpty(v as String?) ?? fallback ?? '';

    String? _readOptString(dynamic v) => JsonUtility.nullIfEmpty(v as String?);

    int _readInt(dynamic v, {int defaultValue = 0}) =>
        JsonUtility.asNum<int>(v, (n) => n.toInt()) ?? defaultValue;

    double? _readOptDouble(dynamic v) =>
        JsonUtility.asNum<double>(v, (n) => n.toDouble());

    final nameRaw = _readString(json['name']);
    final displayNameOrFormattedName =
        JsonUtility.nullIfEmpty(json['display_name'] as String?) ??
            Utility.formatString(nameRaw);

    final entryPoint = json['entry'] as GeoPoint;

    return Venue(
      id: id,
      name: nameRaw,
      displayName: displayNameOrFormattedName,
      logoUrl: _readOptString(json['logo_url']),
      type: venueTypeFromString(_readString(json['type'])),
      corners: JsonUtility.listGeoPoints(json['corners']),
      rating: _readOptDouble(json['rating']),
      ratingCount: _readInt(json['rating_count'], defaultValue: 0),
      description: _readOptString(json['description']) ?? '',
      countryCode:
      _readString(json['country_code']).toLowerCase(), // doc: 2-char
      city: _readString(json['city']).toLowerCase(),
      likeCount: _readInt(json['like_count'], defaultValue: 0),
      favoriteCount: _readInt(json['favorite_count'], defaultValue: 0),
      visitCount: _readInt(json['visit_count'], defaultValue: 0),
      openingHours:
      OpeningHours.fromJson((json['opening_hours'] as Map?)?.cast<String, dynamic>()),
      entry: entryPoint,
      geohash: _readString(json['geohash']), // required by doc
      defaultAgeRestriction:
      _readInt(json['default_age_restriction'], defaultValue: 18),
      capacity: _readInt(json['capacity'], defaultValue: 100),
      coverImageUrl: _readOptString(json['cover_image_url']),
      moodImageUrls: JsonUtility.listStrings(json['mood_image_urls']),
      timeZoneId: _readOptString(json['time_zone_id'])?.toLowerCase(),
      createdAt: json['created_at'] as Timestamp?,
      updatedAt: json['updated_at'] as Timestamp?,
      defaultEntryPrice: json['default_entry_price'] ?? 0, // doc
      links: JsonUtility.mapStringString(json['links']),
      email: _readOptString(json['email']),
      phone: _readOptString(json['phone']),
      subscriptionType:
      subscriptionTypeFromString(_readOptString(json['subscription_type'])),
      dressCode: _readOptString(json['dress_code']),
      tags: JsonUtility.listStrings(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      // basics
      'name': name,
      'display_name': displayName, // doc required
      'logo_url': logoUrl,
      'type': venueTypeToString(type),

      // location
      'entry': entry,
      'geohash': geohash, // doc required
      'country_code': countryCode,
      'city': city,
      'corners': corners,

      // metrics (doc fields)
      'rating': rating, // doc uses `rating`
      'rating_count': ratingCount,
      'like_count': likeCount,
      'favorite_count': favoriteCount,
      'visit_count': visitCount,

      // opening hours
      'opening_hours': openingHours.toJson(),

      // media
      'cover_image_url': coverImageUrl,
      'mood_image_urls': moodImageUrls,

      // auditing
      'created_at': createdAt,
      'updated_at': updatedAt,

      'default_entry_price': defaultEntryPrice, // doc

      // links & contact
      'links': links.isEmpty ? null : links,
      'email': email,
      'phone': phone,

      // subscription
      'subscription_type': subscriptionTypeToString(subscriptionType),

      // age/capacity
      'default_age_restriction': defaultAgeRestriction,
      'capacity': capacity,

      // extras (doc)
      'dress_code': dressCode,
      'tags': tags.isEmpty ? null : tags,
      'time_zone_id': timeZoneId,
      'description': description,
    };

    // Remove nulls to keep payload clean & DRY.
    map.removeWhere((key, value) => value == null);
    return map;
  }

  Venue copyWith({
    String? id,
    String? name,
    String? displayName,
    String? logoUrl,
    String? description,
    String? countryCode,
    String? city,
    String? timeZoneId,
    GeoPoint? entry,
    String? geohash,
    List<GeoPoint>? corners,
    VenueType? type,
    double? rating,
    int? ratingCount,
    int? likeCount,
    int? favoriteCount,
    int? visitCount,
    String? coverImageUrl,
    List<String>? moodImageUrls,
    OpeningHours? openingHours,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    int? defaultEntryPrice,
    Map<String, String>? links,
    String? email,
    String? phone,
    SubscriptionTypeClub? subscriptionType,
    int? defaultAgeRestriction,
    int? capacity,
    String? dressCode,
    List<String>? tags,
  }) {
    return Venue(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      countryCode: countryCode ?? this.countryCode,
      city: city ?? this.city,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      entry: entry ?? this.entry,
      geohash: geohash ?? this.geohash,
      corners: corners ?? this.corners,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      likeCount: likeCount ?? this.likeCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      visitCount: visitCount ?? this.visitCount,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      moodImageUrls: moodImageUrls ?? this.moodImageUrls,
      openingHours: openingHours ?? this.openingHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      defaultEntryPrice: defaultEntryPrice,
      links: links ?? this.links,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      defaultAgeRestriction:
      defaultAgeRestriction ?? this.defaultAgeRestriction,
      capacity: capacity ?? this.capacity,
      dressCode: dressCode ?? this.dressCode,
      tags: tags ?? this.tags,
    );
  }

  // ---------- Helpers ----------
  bool isOpenNow(DateTime venueLocalNow) => openingHours.isOpenAt(venueLocalNow);

  int effectiveAgeRestriction(DateTime venueLocalNow) =>
      openingHours.activeAgeRestriction(venueLocalNow) ?? defaultAgeRestriction;

  bool _isActiveUntil(Timestamp? until, DateTime nowUtc) =>
      until != null && until.toDate().isAfter(nowUtc);

  bool get hasAccessUserData => false; // keep behavior; evaluate in service
}
