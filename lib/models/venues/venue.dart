import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import '../../shared/utility/json_utility.dart';
import '/shared/utility/utility.dart'; // Utility
import 'package:nightowlcode/shared/utility/lat_lng.dart';

// ---------- Enum (de)serializers ----------
VenueType venueTypeFromString(String s) => VenueType.values.firstWhere(
      (e) => describeEnum(e).toLowerCase() == (s.trim().toLowerCase()),
  orElse: () => VenueType.unknown,
);

String venueTypeToString(VenueType t) => describeEnum(t);

DressCodeType dressCodeTypeFromString(String s) => DressCodeType.values.firstWhere(
      (e) => describeEnum(e).toLowerCase() == (s.trim().toLowerCase()),
  orElse: () => DressCodeType.none,
);

String dressCodeTypeToString(DressCodeType t) => describeEnum(t);


SubscriptionTypesVenue subscriptionTypeFromString(String? s) {
  final v = (s ?? '').trim().toLowerCase();
  return SubscriptionTypesVenue.values.firstWhere(
        (e) => describeEnum(e) == v,
    orElse: () => SubscriptionTypesVenue.free,
  );
}

String subscriptionTypeToString(SubscriptionTypesVenue t) => describeEnum(t);
String? colorToHex(Color? color) => color == null ? null : '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
Color? colorFromHex(String? hex) => hex == null ? null : Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);

// ---------- Minutes helper ----------
int _toMinutes(int hour, int minute) => (hour * 60) + minute;

// ---------- DaySchedule ----------
@immutable
class DaySchedule {
  final bool isClosed;
  final int? openMinutes; // null when isClosed; otherwise 0..1439
  final int? closeMinutes; // null when isClosed; otherwise 0..1439
  final int? ageRestriction;
  final DressCodeType? dressCode;
  final double? entryPrice;

  const DaySchedule({
    this.isClosed = true,
    this.openMinutes,
    this.closeMinutes,
    this.ageRestriction,
    this.dressCode,
    this.entryPrice,
  }) : assert(isClosed || (openMinutes != null && closeMinutes != null && openMinutes != closeMinutes),
  'Non-closed days must have valid open/close minutes');

  Map<String, dynamic> toJson() => {
    'is_closed': isClosed,
    if (!isClosed) 'open': openMinutes,
    if (!isClosed) 'close': closeMinutes,
    if (ageRestriction != null) 'age_restriction': ageRestriction,
    if (dressCode != null) 'dress_code': dressCodeTypeToString(dressCode!),
    if (entryPrice != null) 'entry_price': entryPrice,
  };

  factory DaySchedule.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const DaySchedule();
    }
    final isClosed = json['is_closed'] as bool? ?? true;
    return DaySchedule(
      isClosed: isClosed,
      openMinutes: isClosed ? null : JsonUtility.asNum<int>(json['open'], (n) => n.toInt()),
      closeMinutes: isClosed ? null : JsonUtility.asNum<int>(json['close'], (n) => n.toInt()),
      ageRestriction: JsonUtility.asNum<int>(json['age_restriction'], (n) => n.toInt()),
      dressCode: dressCodeTypeFromString(json['dress_code'] as String? ?? ''),
      entryPrice: JsonUtility.asNum<double>(json['entry_price'], (n) => n.toDouble()),
    );
  }

  DaySchedule copyWith({
    bool? isClosed,
    int? openMinutes,
    int? closeMinutes,
    int? ageRestriction,
    DressCodeType? dressCode,
    double? entryPrice,
    bool clearAgeRestriction = false,
    bool clearDressCode = false,
    bool clearEntryPrice = false,
  }) {
    return DaySchedule(
      isClosed: isClosed ?? this.isClosed,
      openMinutes: isClosed == true ? null : (openMinutes ?? this.openMinutes),
      closeMinutes: isClosed == true ? null : (closeMinutes ?? this.closeMinutes),
      ageRestriction: clearAgeRestriction ? null : (ageRestriction ?? this.ageRestriction),
      dressCode: clearDressCode ? null : (dressCode ?? this.dressCode),
      entryPrice: clearEntryPrice ? null : (entryPrice ?? this.entryPrice),
    );
  }
}

// ---------- ExceptionHours (domain uses DateTime only) ----------

@immutable
class ExceptionHours {
  final DateTime date; // Y/M/D only
  final bool isClosed;
  final int? openMinutes;
  final int? closeMinutes;
  final int? ageRestriction;
  final DressCodeType? dressCode;
  final double? entryPrice;

  const ExceptionHours({
    required this.date,
    this.isClosed = true,
    this.openMinutes,
    this.closeMinutes,
    this.ageRestriction,
    this.dressCode,
    this.entryPrice,
  }) : assert(isClosed || (openMinutes != null && closeMinutes != null && openMinutes != closeMinutes),
  'Non-closed exception days must have valid open/close minutes');

  Map<String, dynamic> toJson() => {
    'date': DateTime(date.year, date.month, date.day).toIso8601String(),
    'is_closed': isClosed,
    if (!isClosed) 'open': openMinutes,
    if (!isClosed) 'close': closeMinutes,
    if (ageRestriction != null) 'age_restriction': ageRestriction,
    if (dressCode != null) 'dress_code': dressCodeTypeToString(dressCode!),
    if (entryPrice != null) 'entry_price': entryPrice,
  };

  factory ExceptionHours.fromJson(Map<String, dynamic> json) {
    final raw = json['date'];
    final parsed = raw is String ? DateTime.parse(raw) : DateTime.now();
    final onlyDate = DateTime(parsed.year, parsed.month, parsed.day);
    final isClosed = json['is_closed'] as bool? ?? true;
    return ExceptionHours(
      date: onlyDate,
      isClosed: isClosed,
      openMinutes: isClosed ? null : JsonUtility.asNum<int>(json['open'], (n) => n.toInt()),
      closeMinutes: isClosed ? null : JsonUtility.asNum<int>(json['close'], (n) => n.toInt()),
      ageRestriction: JsonUtility.asNum<int>(json['age_restriction'], (n) => n.toInt()),
      dressCode: dressCodeTypeFromString(json['dress_code'] as String? ?? ''),
      entryPrice: JsonUtility.asNum<double>(json['entry_price'], (n) => n.toDouble()),
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
    final minutes = _toMinutes(localNow.hour, localNow.minute);
    final today = DateTime(localNow.year, localNow.month, localNow.day);

    final exception = exceptions.firstWhere(
          (e) => e.date == today,
      orElse: () => ExceptionHours(date: DateTime(1970, 1, 1)),
    );

    final DaySchedule schedule = (exception.date == today)
        ? DaySchedule(
      isClosed: exception.isClosed,
      openMinutes: exception.openMinutes,
      closeMinutes: exception.closeMinutes,
      ageRestriction: exception.ageRestriction,
      dressCode: exception.dressCode,
      entryPrice: exception.entryPrice,
    )
        : week[(localNow.weekday - 1) % 7];

    if (schedule.isClosed) return false;

    final open = schedule.openMinutes!;
    final close = schedule.closeMinutes!;
    if (open == close) return false; // Shouldn't happen due to assert

    if (close > open) {
      return minutes >= open && minutes < close;
    } else {
      // Overnight (e.g., 22:00–03:00)
      return minutes >= open || minutes < close;
    }
  }

  bool isOpenToday(DateTime localNow) {
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final exception = exceptions.firstWhere(
          (e) => e.date == today,
      orElse: () => ExceptionHours(date: DateTime(1970, 1, 1)),
    );
    final schedule = (exception.date == today)
        ? DaySchedule(
      isClosed: exception.isClosed,
      openMinutes: exception.openMinutes,
      closeMinutes: exception.closeMinutes,
      ageRestriction: exception.ageRestriction,
      dressCode: exception.dressCode,
      entryPrice: exception.entryPrice,
    )
        : week[(localNow.weekday - 1) % 7];
    return !schedule.isClosed;
  }

  int? activeAgeRestriction(DateTime localNow) {
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final exception = exceptions.firstWhere(
          (e) => e.date == today,
      orElse: () => ExceptionHours(date: DateTime(1970, 1, 1)),
    );
    return (exception.date == today)
        ? exception.ageRestriction
        : week[(localNow.weekday - 1) % 7].ageRestriction;
  }

  DressCodeType? activeDressCode(DateTime localNow) {
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final exception = exceptions.firstWhere(
          (e) => e.date == today,
      orElse: () => ExceptionHours(date: DateTime(1970, 1, 1)),
    );
    return (exception.date == today)
        ? exception.dressCode
        : week[(localNow.weekday - 1) % 7].dressCode;
  }

  double? activeEntryPrice(DateTime localNow) {
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final exception = exceptions.firstWhere(
          (e) => e.date == today,
      orElse: () => ExceptionHours(date: DateTime(1970, 1, 1)),
    );
    return (exception.date == today)
        ? exception.entryPrice
        : week[(localNow.weekday - 1) % 7].entryPrice;
  }
}

// ---------- Venue (domain) ----------
@immutable
class Venue {
  final String id; // REQUIRED

  // Basics
  final String name; // REQUIRED
  final String displayName; // REQUIRED
  final VenueType type; // REQUIRED
  final LatLng entry; // REQUIRED
  final String geohash; // REQUIRED
  final String countryCode; // ISO-3166 alpha-2 (lowercase)
  final String city;

  // Auditing (domain uses DateTime)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ---------- Media ----------
  final String? logoUrl;
  final String? coverImageUrl;
  final List<String> moodImageUrls;

  // ---------- Identity & Description ----------
  final String description;
  final String? timeZoneId; // IANA, optional

  final OpeningHours openingHours;
  final SubscriptionTypesVenue subscriptionType;

  final int defaultAgeRestriction;
  final int capacity;

  final List<LatLng> corners;
  final List<String> tagids;

  final bool isVerified;
  final String? primaryColorHex;
  final String? secondaryColorHex;
  final String? fontFamily;
  final DressCodeType defaultDressCode;

  // ---------- Aggregates / Metrics ----------
  final double? rating;
  //TODO Subcollection that handles all ratings for each venue?.
  final double defaultEntryPrice;
  final int ratingCount;
  final int likeCount;
  final int favoriteCount;
  final int visitCount;

  // ---------- Extra Fields ----------
  final Map<String, String> links;
  final String? email;
  final String? phone;

   Venue({
    required this.id,
    required this.name,
    required this.displayName,
    required this.type,
    required this.corners,
    required this.countryCode,
    required this.city,
    required this.openingHours,
    required this.entry,
    required this.geohash,
    this.defaultDressCode = DressCodeType.none,
    this.isVerified = false,
    this.primaryColorHex,
    this.secondaryColorHex,
    this.fontFamily,
    this.ratingCount = 0,
    this.description = "",
    this.likeCount = 0,
    this.favoriteCount = 0,
    this.visitCount = 0,
    this.defaultAgeRestriction = 18,
    this.capacity = 100,
    this.logoUrl,
    this.rating,
    this.coverImageUrl,
    this.moodImageUrls = const [],
    this.timeZoneId,
    this.createdAt,
    this.updatedAt,
    this.defaultEntryPrice = 0.0,
    this.links = const {},
    this.email,
    this.phone,
    this.subscriptionType = SubscriptionTypesVenue.free,
    this.tagids = const [],
  });

  // ---------- Domain (de)serialization (platform-agnostic) ----------
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

    final entryMap = (json['entry'] as Map).cast<String, dynamic>();
    final entry = LatLng.fromJson(entryMap);

    final cornersList = (json['corners'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(LatLng.fromJson)
        .toList();

    DateTime? _readDate(dynamic v) {
      final s = v as String?;
      return s == null ? null : DateTime.parse(s);
    }

    return Venue(
      id: id,
      name: nameRaw,
      displayName: displayNameOrFormattedName,
      logoUrl: _readOptString(json['logo_url']),
      type: venueTypeFromString(_readString(json['type'])),
      corners: cornersList,
      rating: _readOptDouble(json['rating']),
      ratingCount: _readInt(json['rating_count'], defaultValue: 0),
      description: _readOptString(json['description']) ?? '',
      countryCode: _readString(json['country_code']).toLowerCase(),
      city: _readString(json['city']).toLowerCase(),
      likeCount: _readInt(json['like_count'], defaultValue: 0),
      favoriteCount: _readInt(json['favorite_count'], defaultValue: 0),
      visitCount: _readInt(json['visit_count'], defaultValue: 0),
      openingHours: OpeningHours.fromJson(
        (json['opening_hours'] as Map?)?.cast<String, dynamic>(),
      ),
      entry: entry,
      geohash: _readString(json['geohash']),
      defaultAgeRestriction:
      _readInt(json['default_age_restriction'], defaultValue: 18),
      capacity: _readInt(json['capacity'], defaultValue: 100),
      coverImageUrl: _readOptString(json['cover_image_url']),
      moodImageUrls: JsonUtility.listStrings(json['mood_image_urls']),
      timeZoneId: _readOptString(json['time_zone_id']),
      createdAt: _readDate(json['created_at']),
      updatedAt: _readDate(json['updated_at']),
      defaultEntryPrice: JsonUtility.asNum<double>(
          json['default_entry_price'], (n) => n.toDouble()) ??
          0.0,
      links: JsonUtility.mapStringString(json['links']),
      email: _readOptString(json['email']),
      phone: _readOptString(json['phone']),
      subscriptionType:
      subscriptionTypeFromString(_readOptString(json['subscription_type'])),
      isVerified: json['is_verified'] as bool? ?? false,
      primaryColorHex: _readOptString(json['primary_color_hex']),
      secondaryColorHex: _readOptString(json['secondary_color_hex']),
      fontFamily: _readOptString(json['font_family']),
      defaultDressCode: dressCodeTypeFromString(_readString(json['default_dress_code'], fallback: 'none')),
      tagids: JsonUtility.listStrings(json['tag_ids']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      // basics
      'name': name,
      'display_name': displayName,
      'logo_url': logoUrl,
      'type': venueTypeToString(type),

      // location (domain JSON uses LatLng maps)
      'entry': entry.toJson(),
      'geohash': geohash,
      'country_code': countryCode,
      'city': city,
      'corners': corners.map((c) => c.toJson()).toList(),

      // metrics
      'rating': rating,
      'rating_count': ratingCount,
      'like_count': likeCount,
      'favorite_count': favoriteCount,
      'visit_count': visitCount,

      // opening hours
      'opening_hours': openingHours.toJson(),

      // media
      'cover_image_url': coverImageUrl,
      'mood_image_urls': moodImageUrls,

      // auditing (domain JSON uses ISO8601 strings)
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),

      'default_entry_price': defaultEntryPrice,

      // links & contact
      'links': links.isEmpty ? null : links,
      'email': email,
      'phone': phone,

      // subscription
      'subscription_type': subscriptionTypeToString(subscriptionType),

      // age/capacity
      'default_age_restriction': defaultAgeRestriction,
      'capacity': capacity,

      // extras
      'default_dress_code': dressCodeTypeToString(defaultDressCode),
      'is_verified': isVerified,
      'primary_color_hex': primaryColorHex,
      'secondary_color_hex': secondaryColorHex,
      'font_family': fontFamily,
      'tag_ids': tagids.isEmpty ? null : tagids,
      'time_zone_id': timeZoneId,
      'description': description,
    };

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
    LatLng? entry,
    String? geohash,
    List<LatLng>? corners,
    VenueType? type,
    double? rating,
    int? ratingCount,
    int? likeCount,
    int? favoriteCount,
    int? visitCount,
    String? coverImageUrl,
    List<String>? moodImageUrls,
    OpeningHours? openingHours,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? defaultEntryPrice,
    Map<String, String>? links,
    String? email,
    String? phone,
    SubscriptionTypesVenue? subscriptionType,
    int? defaultAgeRestriction,
    int? capacity,
    bool? isVerified,
    String? primaryColorHex,
    String? secondaryColorHex,
    String? fontFamily,
    DressCodeType? defaultDressCode,
    List<String>? tagids,
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
      defaultEntryPrice: defaultEntryPrice ?? this.defaultEntryPrice,
      links: links ?? this.links,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      defaultAgeRestriction:
      defaultAgeRestriction ?? this.defaultAgeRestriction,
      capacity: capacity ?? this.capacity,
      isVerified: isVerified ?? this.isVerified,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      secondaryColorHex: secondaryColorHex ?? this.secondaryColorHex,
      fontFamily: fontFamily ?? this.fontFamily,
      defaultDressCode: defaultDressCode ?? this.defaultDressCode,
      tagids: tagids ?? this.tagids,
    );
  }

  bool isOpenNow(DateTime venueLocalNow) => openingHours.isOpenAt(venueLocalNow);
  bool isOpenToday(DateTime venueLocalNow) => openingHours.isOpenToday(venueLocalNow);

  int effectiveAgeRestriction(DateTime venueLocalNow) =>
      openingHours.activeAgeRestriction(venueLocalNow) ?? defaultAgeRestriction;
  DressCodeType effectiveDressCode(DateTime venueLocalNow) =>
      openingHours.activeDressCode(venueLocalNow) ?? defaultDressCode;

  double effectiveEntryPrice(DateTime venueLocalNow) =>
      openingHours.activeEntryPrice(venueLocalNow) ?? defaultEntryPrice;
}
