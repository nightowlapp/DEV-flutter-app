  import 'dart:ui';

  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/foundation.dart';
  import 'package:nightowlcode/shared/constants/colors.dart';
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

  DressCodeType dressCodeTypeFromString(String s) =>
      DressCodeType.values.firstWhere(
        (e) => describeEnum(e).toLowerCase() == (s.trim().toLowerCase()),
        orElse: () => DressCodeType.none,
      );

  String dressCodeTypeToString(DressCodeType t) => describeEnum(t);

  SubscriptionTypesVenue subscriptionTypeFromString(String? s) {
    final v = (s ?? '').trim().toLowerCase();
    return SubscriptionTypesVenue.values.firstWhere(
      (e) => describeEnum(e).toLowerCase() == v,
      orElse: () => SubscriptionTypesVenue.free,
    );
  }

  String subscriptionTypeToString(SubscriptionTypesVenue t) => describeEnum(t);

  String? colorToHex(Color? color) => color == null
      ? null
      : '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';

  Color? colorFromHex(String? hex) {
    // Robustly handle #RRGGBB and #AARRGGBB (returns null for invalid)
    if (hex == null) return null;
    final h = hex.replaceAll('#', '');
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    } else if (h.length == 8) {
      return Color(int.parse(h, radix: 16));
    }
    return null;
  }

  // ---------- Minutes helper ----------
  int _toMinutes(int hour, int minute) => (hour * 60) + minute;

  // ---------- DaySchedule ----------
  @immutable
  // ---------- DaySchedule ----------
  class DaySchedule {
    final bool isClosed;
    final int? openMinutes; // 0..1439
    final int? closeMinutes; // 0..1439
    final int? ageRestriction;
    final DressCodeType? dressCode;
    final double? entryPrice;
    final String? offerImageUrl;

    const DaySchedule({
      this.isClosed = true,
      this.openMinutes,
      this.closeMinutes,
      this.ageRestriction,
      this.dressCode,
      this.entryPrice,
      this.offerImageUrl,
    }) : assert(
            isClosed ||
                (openMinutes != null &&
                    closeMinutes != null &&
                    openMinutes != closeMinutes),
            'Non-closed days must have valid open/close minutes',
          );

    Map<String, dynamic> toJson() => {
          'is_closed': isClosed,
          if (!isClosed) 'open': openMinutes,
          if (!isClosed) 'close': closeMinutes,
          if (ageRestriction != null) 'age_restriction': ageRestriction,
          if (dressCode != null) 'dress_code': dressCodeTypeToString(dressCode!),
          if (entryPrice != null) 'entry_price': entryPrice,
          if (offerImageUrl != null) 'offer_image_url': offerImageUrl,
        };

    // ✅ Defensive parsing: if invalid, treat as closed
    factory DaySchedule.fromJson(Map<String, dynamic>? json) {
      if (json == null) return const DaySchedule();

      bool isClosed = (json['is_closed'] as bool?) ?? true;

      int? _asInt(dynamic v) {
        if (v == null) return null;
        final n = (v is num) ? v.toInt() : int.tryParse(v.toString());
        if (n == null) return null;
        // clamp to 0..1439
        if (n < 0) return 0;
        if (n > 1439) return 1439;
        return n;
      }

      int? open = isClosed ? null : _asInt(json['open']);
      int? close = isClosed ? null : _asInt(json['close']);

      // If non-closed but invalid times → coerce to closed
      if (!isClosed && (open == null || close == null || open == close)) {
        isClosed = true;
        open = null;
        close = null;
      }

      return DaySchedule(
        isClosed: isClosed,
        openMinutes: open,
        closeMinutes: close,
        ageRestriction:
            JsonUtility.asNum<int>(json['age_restriction'], (n) => n.toInt()),
        dressCode: dressCodeTypeFromString(json['dress_code'] as String? ?? ''),
        entryPrice:
            JsonUtility.asNum<double>(json['entry_price'], (n) => n.toDouble()),
        offerImageUrl:
            JsonUtility.nullIfEmpty(json['offer_image_url'] as String?),
      );
    }

    DaySchedule copyWith({
      bool? isClosed,
      int? openMinutes,
      int? closeMinutes,
      int? ageRestriction,
      DressCodeType? dressCode,
      double? entryPrice,
      String? offerImageUrl,
      bool clearAgeRestriction = false,
      bool clearDressCode = false,
      bool clearEntryPrice = false,
      bool clearOfferImage = false,
    }) {
      final nextClosed = isClosed ?? this.isClosed;
      return DaySchedule(
        isClosed: nextClosed,
        openMinutes: nextClosed ? null : (openMinutes ?? this.openMinutes),
        closeMinutes: nextClosed ? null : (closeMinutes ?? this.closeMinutes),
        ageRestriction:
            clearAgeRestriction ? null : (ageRestriction ?? this.ageRestriction),
        dressCode: clearDressCode ? null : (dressCode ?? this.dressCode),
        entryPrice: clearEntryPrice ? null : (entryPrice ?? this.entryPrice),
        offerImageUrl:
            clearOfferImage ? null : (offerImageUrl ?? this.offerImageUrl),
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
    }) : assert(
            isClosed ||
                (openMinutes != null &&
                    closeMinutes != null &&
                    openMinutes != closeMinutes),
            'Non-closed exception days must have valid open/close minutes',
          );

    Map<String, dynamic> toJson() => {
          'date': DateTime(date.year, date.month, date.day).toIso8601String(),
          'is_closed': isClosed,
          if (!isClosed) 'open': openMinutes,
          if (!isClosed) 'close': closeMinutes,
          if (ageRestriction != null) 'age_restriction': ageRestriction,
          if (dressCode != null) 'dress_code': dressCodeTypeToString(dressCode!),
          if (entryPrice != null) 'entry_price': entryPrice,
        };

    // ✅ Defensive parsing like DaySchedule
    factory ExceptionHours.fromJson(Map<String, dynamic> json) {
      final raw = json['date'];
      final parsed = raw is String
          ? DateTime.tryParse(raw) ?? DateTime.now()
          : DateTime.now();
      final d = DateTime(parsed.year, parsed.month, parsed.day);

      bool isClosed = (json['is_closed'] as bool?) ?? true;

      int? _asInt(dynamic v) {
        if (v == null) return null;
        final n = (v is num) ? v.toInt() : int.tryParse(v.toString());
        if (n == null) return null;
        if (n < 0) return 0;
        if (n > 1439) return 1439;
        return n;
      }

      int? open = isClosed ? null : _asInt(json['open']);
      int? close = isClosed ? null : _asInt(json['close']);

      if (!isClosed && (open == null || close == null || open == close)) {
        isClosed = true;
        open = null;
        close = null;
      }

      return ExceptionHours(
        date: d,
        isClosed: isClosed,
        openMinutes: open,
        closeMinutes: close,
        ageRestriction:
            JsonUtility.asNum<int>(json['age_restriction'], (n) => n.toInt()),
        dressCode: dressCodeTypeFromString(json['dress_code'] as String? ?? ''),
        entryPrice:
            JsonUtility.asNum<double>(json['entry_price'], (n) => n.toDouble()),
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

    bool isOpenAt(DateTime localNow) =>
        statusAt(localNow).phase == OpeningPhase.open;

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

  // ===== Add below your OpeningHours class (same file) =====

  enum OpeningPhase {
    open, // currently open
    opensLaterToday, // closed now, opens later today
    opensTomorrow, // closed today, opens tomorrow
    closedToday, // closed and no info for tomorrow
  }

  @immutable
  class OpeningStatus {
    final OpeningPhase phase;
    final int? openMinutes; // next opening minute-of-day (if applicable)
    final int? closeMinutes; // closing minute-of-day for current open window
    final bool
        fromYesterday; // true if currently open due to yesterday's overnight span

    const OpeningStatus({
      required this.phase,
      this.openMinutes,
      this.closeMinutes,
      this.fromYesterday = false,
    });
  }

  extension OpeningStatusFormat on OpeningStatus {
    /// Human-readable label with "opens soon / closes soon" support.
    ///
    /// [localNow] must be venue-local time.
    /// [soonThresholdMinutes] controls when we say "soon" (default 60).
    String label({
      DateTime? localNow,
      int soonThresholdMinutes = 60,
    }) {
      final now = (localNow ?? DateTime.now()).toLocal();
      final nowM = _toMinutes(now.hour, now.minute);

      String fmt(int m) {
        final h = (m ~/ 60) % 24;
        final mm = m % 60;
        return '${h.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
      }

      int _deltaMinutes(int from, int to) {
        // difference within [0, 1440) – handles overnight by wrapping
        var diff = to - from;
        if (diff < 0) diff += 24 * 60;
        return diff;
      }

      switch (phase) {
        case OpeningPhase.open:
          if (closeMinutes == null) {
            return 'Open now';
          }

          final minutesToClose = _deltaMinutes(nowM, closeMinutes!);

          // "Closes soon" window
          if (minutesToClose > 0 && minutesToClose <= soonThresholdMinutes) {
            return 'Closes in $minutesToClose min';
          }

          return 'Open now · until ${fmt(closeMinutes!)}';

        case OpeningPhase.opensLaterToday:
          if (openMinutes == null) {
            return 'Closed';
          }

          final minutesToOpen = _deltaMinutes(nowM, openMinutes!);

          // "Opens soon" window
          if (minutesToOpen > 0 && minutesToOpen <= soonThresholdMinutes) {
            return 'Opens in $minutesToOpen min';
          }

          return 'Opens ${fmt(openMinutes!)}';

        case OpeningPhase.opensTomorrow:
        // You probably don't want "opens soon" here since it's > 60 min away.
          if (openMinutes != null) {
            return 'Opens ${fmt(openMinutes!)}';
          }
          return '';

        case OpeningPhase.closedToday:
          return '';
      }
    }
  }


  extension OpeningHoursStatus on OpeningHours {
    /// Structured status for UI. `localNow` must be venue local time.
    OpeningStatus statusAt(DateTime localNow) {
      final today = DateTime(localNow.year, localNow.month, localNow.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));
      final nowM = _toMinutes(localNow.hour, localNow.minute);

      DaySchedule? t = _scheduleForDate(today);
      DaySchedule? y = _scheduleForDate(yesterday);
      DaySchedule? tm = _scheduleForDate(tomorrow);

      bool valid(DaySchedule? s) =>
          s != null &&
          !s.isClosed &&
          s.openMinutes != null &&
          s.closeMinutes != null;
      bool overnight(DaySchedule s) => s.closeMinutes! <= s.openMinutes!;

      // 1) Open now due to YESTERDAY'S overnight (e.g., 21:00–03:00 and it's 01:00 today)
      if (valid(y) && overnight(y!)) {
        if (nowM < y.closeMinutes!) {
          return OpeningStatus(
            phase: OpeningPhase.open,
            closeMinutes: y.closeMinutes,
            fromYesterday: true,
          );
        }
      }

      // 2) TODAY's schedule
      if (valid(t)) {
        final open = t!.openMinutes!;
        final close = t.closeMinutes!;
        if (!overnight(t)) {
          if (nowM >= open && nowM < close) {
            return OpeningStatus(phase: OpeningPhase.open, closeMinutes: close);
          }
          if (nowM < open) {
            return OpeningStatus(
                phase: OpeningPhase.opensLaterToday, openMinutes: open);
          }
          // closed for the rest of today
          if (valid(tm)) {
            return OpeningStatus(
                phase: OpeningPhase.opensTomorrow, openMinutes: tm!.openMinutes);
          }
          return const OpeningStatus(phase: OpeningPhase.closedToday);
        } else {
          // Overnight (e.g., 21:00–03:00)
          if (nowM >= open) {
            return OpeningStatus(phase: OpeningPhase.open, closeMinutes: close);
          }
          // later today (tonight)
          return OpeningStatus(
              phase: OpeningPhase.opensLaterToday, openMinutes: open);
        }
      }

      // 3) No valid schedule today
      if (valid(tm)) {
        return OpeningStatus(
            phase: OpeningPhase.opensTomorrow, openMinutes: tm!.openMinutes);
      }
      return const OpeningStatus(phase: OpeningPhase.closedToday);
    }

    // --- helper: same exception/weekly resolution, but date-safe ---
    DaySchedule? _scheduleForDate(DateTime dateLocal) {
      final d = DateTime(dateLocal.year, dateLocal.month, dateLocal.day);

      ExceptionHours? exc;
      for (final e in exceptions) {
        final ed = DateTime(e.date.year, e.date.month, e.date.day);
        if (ed.year == d.year && ed.month == d.month && ed.day == d.day) {
          exc = e;
          break;
        }
      }
      if (exc != null) {
        return DaySchedule(
          isClosed: exc.isClosed,
          openMinutes: exc.openMinutes,
          closeMinutes: exc.closeMinutes,
          ageRestriction: exc.ageRestriction,
          dressCode: exc.dressCode,
          entryPrice: exc.entryPrice,
        );
      }

      // Monday=1 -> index 0
      final idx = (d.weekday + 6) % 7;
      if (week.isEmpty || idx >= week.length) return null;
      return week[idx];
    }
  }

  // Put this in the same file as your OpeningHours model (e.g., below the class)
  extension OpeningHoursSimpleFormat on OpeningHours {
    /// Returns today's range as 24h parts + flags.
    /// - open/close: "HH:mm"
    /// - nextDay: true when close time is on the next day (overnight)
    /// - isClosed: true when closed or missing times
    ({String open, String close, bool nextDay, bool isClosed}) todayRangeParts24h(
        {DateTime? localNow}) {
      final now = (localNow ?? DateTime.now()).toLocal();
      final d = DateTime(now.year, now.month, now.day);

      // Find exception for today (date-only compare)
      final exc = exceptions.firstWhere(
        (e) =>
            e.date.year == d.year &&
            e.date.month == d.month &&
            e.date.day == d.day,
        orElse: () => ExceptionHours(date: DateTime(1970, 1, 1)),
      );

      final DaySchedule schedule = (exc.date.year == d.year &&
              exc.date.month == d.month &&
              exc.date.day == d.day)
          ? DaySchedule(
              isClosed: exc.isClosed,
              openMinutes: exc.openMinutes,
              closeMinutes: exc.closeMinutes,
              ageRestriction: exc.ageRestriction,
              dressCode: exc.dressCode,
              entryPrice: exc.entryPrice,
            )
          : week[(d.weekday + 6) % 7]; // Mon=1 -> index 0

      String fmt(int minutes) {
        final h = (minutes ~/ 60) % 24;
        final m = minutes % 60;
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
      }

      if (schedule.isClosed ||
          schedule.openMinutes == null ||
          schedule.closeMinutes == null) {
        return (open: '', close: '', nextDay: false, isClosed: true);
      }

      final openM = schedule.openMinutes!;
      final closeM = schedule.closeMinutes!;
      final nextDay = closeM <= openM; // overnight window

      return (
        open: fmt(openM),
        close: fmt(closeM),
        nextDay: nextDay,
        isClosed: false
      );
    }

    /// Keeps your previous string API if you need it elsewhere.
    String todayRangeLabel24h({DateTime? localNow}) {
      final r = todayRangeParts24h(localNow: localNow);
      if (r.isClosed) return 'Closed today';
      return '${r.open} - ${r.close}';
    }
  }

  // Optional convenience on Venue
  extension VenueOpeningRange on Venue {
    ({String open, String close, bool nextDay, bool isClosed}) todayRangeParts24h(
            {DateTime? venueLocalNow}) =>
        openingHours.todayRangeParts24h(localNow: venueLocalNow);

    String todayRangeLabel24h({DateTime? venueLocalNow}) =>
        openingHours.todayRangeLabel24h(localNow: venueLocalNow);
  }

  // ---------- Venue (domain) ----------
  @immutable
  class Venue {
    final String id; // REQUIRED

    // Basics
    final String? companyNumber;
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
    final String? logoUrl; // venue_images/id/logo.webp
    final String? coverImageUrl; // venue_images/id/cover.webp
    final String? barCard; // venue_images/id/bar_card.pdf
    final List<String>
        moodImageUrls; // venue_images/id/mood_images/   // Folder with many images
    final String? defaultOfferUrl; // // venue_images/id/default_offer.webp
    final String?
        dailyOfferUrls; // // venue_images/id/daily_offers/   // Folder with max 1 image for each day

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
      this.companyNumber,
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
      this.barCard,
      this.moodImageUrls = const [],
      this.defaultOfferUrl,
      this.dailyOfferUrls,
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
        if (v == null) return null;
        if (v is DateTime) return v;
        if (v is Timestamp) return v.toDate();
        if (v is int) return DateTime.fromMillisecondsSinceEpoch(v, isUtc: false);
        if (v is String) return DateTime.tryParse(v);
        return null;
      }

      // 🔥 NEW: read raw cover + logo
      final rawCover = _readOptString(json['cover_image_url']);
      final rawLogo  = _readOptString(json['logo_url']);

      // 🔥 NEW: coalesce cover → logo
      String? _effectiveCover(String? cover, String? logo) {
        final c = cover?.trim();
        if (c != null && c.isNotEmpty) return c;
        final l = logo?.trim();
        if (l != null && l.isNotEmpty) return l;
        return null;
      }

      final effectiveCover = _effectiveCover(rawCover, rawLogo);

      // (optional but very helpful for debugging)
      debugPrint(
        'Venue[$id] fromJson: rawCover="$rawCover" rawLogo="$rawLogo" effectiveCover="$effectiveCover"',
      );

      return Venue(
        id: id,
        companyNumber: _readString(json['company_number']),
        name: nameRaw,
        displayName: displayNameOrFormattedName,

        // media
        logoUrl: rawLogo,
        coverImageUrl: effectiveCover,  // 👈 now cover uses logo if cover is empty

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
        barCard: _readOptString(json['bar_card_url']),
        moodImageUrls: JsonUtility.listStrings(json['mood_image_urls']),
        defaultOfferUrl: _readOptString(json['default_offer_url']),
        dailyOfferUrls: _readOptString(json['daily_offer_urls']),
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
        defaultDressCode: dressCodeTypeFromString(
            _readString(json['default_dress_code'], fallback: 'none')),
        tagids: JsonUtility.listStrings(json['tag_ids']),
      );
    }


    Map<String, dynamic> toJson() {
      final map = <String, dynamic>{
        // basics
        'company_number': companyNumber,
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
        'visit_count': visitCount, // TOtal NightOwl visits

        // opening hours
        'opening_hours': openingHours.toJson(),

        // media
        'cover_image_url': coverImageUrl,
        'bar_card_url': barCard,
        'mood_image_urls': moodImageUrls,
        'default_offer_url': defaultOfferUrl,
        'daily_offer_urls': dailyOfferUrls,

        // auditing (domain JSON uses ISO8601 strings)
        if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toUtc().toIso8601String(),

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
      String? companyNumber,
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
      String? barCard,
      List<String>? moodImageUrls,
      String? defaultOfferUrl,
      String? dailyOfferUrls,
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
        companyNumber: companyNumber ?? this.companyNumber,
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
        barCard: barCard ?? this.barCard,
        moodImageUrls: moodImageUrls ?? this.moodImageUrls,
        defaultOfferUrl: defaultOfferUrl ?? this.defaultOfferUrl,
        dailyOfferUrls: dailyOfferUrls ?? this.dailyOfferUrls,
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

    DateTime closeTimeToday() {
      DateTime now = DateTime.now(); // must be venue-local if you use time zones
      final today = DateTime(now.year, now.month, now.day);
      final status = openingHours.statusAt(now);

      DaySchedule _scheduleForDate(DateTime dateLocal) {
        final d = DateTime(dateLocal.year, dateLocal.month, dateLocal.day);

        // exceptions take precedence
        for (final e in openingHours.exceptions) {
          final ed = DateTime(e.date.year, e.date.month, e.date.day);
          if (ed.year == d.year && ed.month == d.month && ed.day == d.day) {
            return DaySchedule(
              isClosed: e.isClosed,
              openMinutes: e.openMinutes,
              closeMinutes: e.closeMinutes,
              ageRestriction: e.ageRestriction,
              dressCode: e.dressCode,
              entryPrice: e.entryPrice,
            );
          }
        }

        final idx = (d.weekday + 6) % 7; // Mon=1 -> 0
        if (openingHours.week.isEmpty || idx >= openingHours.week.length) {
          return const DaySchedule(); // closed
        }
        return openingHours.week[idx];
      }

      bool _overnight(DaySchedule s) =>
          !s.isClosed &&
              s.openMinutes != null &&
              s.closeMinutes != null &&
              s.closeMinutes! <= s.openMinutes!;

      DateTime _compose(DateTime base, int minutes) =>
          DateTime(base.year, base.month, base.day, minutes ~/ 60, minutes % 60);

      // 1) If open now → return end of the current open window
      if (status.phase == OpeningPhase.open && status.closeMinutes != null) {
        final closeM = status.closeMinutes!;
        final nowM = _toMinutes(now.hour, now.minute);
        var base = today;

        // If this is today's overnight window (e.g., 21:00–03:00) and it's past midnight point
        // then close time is tomorrow. For "fromYesterday" (e.g., 01:00 from a 21:00–03:00 yesterday)
        // close is still today.
        if (!status.fromYesterday && closeM <= nowM) {
          base = base.add(const Duration(days: 1));
        }
        return _compose(base, closeM);
      }

      // 2) If closed now but opens later today → return today's closing time
      if (status.phase == OpeningPhase.opensLaterToday) {
        final s = _scheduleForDate(today);
        if (!s.isClosed && s.closeMinutes != null) {
          var base = today;
          if (_overnight(s)) base = base.add(const Duration(days: 1));
          return _compose(base, s.closeMinutes!);
        }
      }

      // 3) Otherwise, find the next open day (within a week) and return its closing time
      for (int i = 1; i <= 7; i++) {
        final d = today.add(Duration(days: i));
        final s = _scheduleForDate(d);
        if (!s.isClosed && s.closeMinutes != null) {
          var base = d;
          if (_overnight(s)) base = base.add(const Duration(days: 1));
          return _compose(base, s.closeMinutes!);
        }
      }

      // Fallback (no schedule at all) – return now to avoid nulls
      return now;
    }


    bool isOpenNow(DateTime venueLocalNow) =>
        openingHours.isOpenAt(venueLocalNow);
    bool isOpenToday(DateTime venueLocalNow) =>
        openingHours.isOpenToday(venueLocalNow);

    int effectiveAgeRestriction(DateTime venueLocalNow) =>
        openingHours.activeAgeRestriction(venueLocalNow) ?? defaultAgeRestriction;
    DressCodeType effectiveDressCode(DateTime venueLocalNow) =>
        openingHours.activeDressCode(venueLocalNow) ?? defaultDressCode;

    double effectiveEntryPrice(DateTime venueLocalNow) =>
        openingHours.activeEntryPrice(venueLocalNow) ?? defaultEntryPrice;

  // ⬇️ Put these INSIDE class Venue (replace your empty `openingHoursToday()`)

  // Returns the range to display for *today*, but if the venue is currently open
  // due to yesterday’s overnight window, it returns yesterday’s range instead.
    ({String open, String close, bool nextDay, bool isClosed})
    openingHoursToday({DateTime? venueLocalNow}) {
      final now = (venueLocalNow ?? DateTime.now()).toLocal();
      final status = openingHours.statusAt(now);

      // If open now from a YESTERDAY overnight span, compute for yesterday.
      final base = (status.phase == OpeningPhase.open && status.fromYesterday)
          ? now.subtract(const Duration(days: 1))
          : now;

      return openingHours.todayRangeParts24h(localNow: base);
    }

  // Label helper: "HH:mm - HH:mm" (+1 if overnight) or "Closed today".
    String openingHoursTodayLabel({DateTime? venueLocalNow}) {
      final r = openingHoursToday(venueLocalNow: venueLocalNow);
      if (r.isClosed) return 'Closed today';
      return '${r.open} - ${r.close}${r.nextDay ? ' +1' : ''}';
    }

  }

  extension VenueMediaEffective on Venue {
    /// Prefer cover; if missing, fall back to logo; otherwise null.
    String? get heroImageUrl {
      final cover = coverImageUrl?.trim();
      final logo  = logoUrl?.trim();

      // 👇 temporary debugging
      debugPrint(
        'Venue[$id] heroImageUrl: cover="$cover" logo="$logo"',
      );

      if (cover != null && cover.isNotEmpty) return cover;
      if (logo  != null && logo.isNotEmpty)  return logo;
      return null;
    }
  }

  extension VenueOpeningSoon on Venue {
    /// True if the venue opens OR closes within [thresholdMinutes] from now.
    bool isOpeningOrClosingSoon(
        DateTime venueLocalNow, {
          int thresholdMinutes = 60,
        }) {
      final now = venueLocalNow.toLocal();
      final status = openingHours.statusAt(now);
      final nowM = _toMinutes(now.hour, now.minute);

      int _deltaMinutes(int from, int to) {
        var diff = to - from;
        if (diff < 0) diff += 24 * 60; // wrap across midnight
        return diff;
      }

      // 🔸 Closing soon?
      if (status.phase == OpeningPhase.open && status.closeMinutes != null) {
        final d = _deltaMinutes(nowM, status.closeMinutes!);
        if (d > 0 && d <= thresholdMinutes) return true;
      }

      // 🔸 Opening soon?
      if (status.phase == OpeningPhase.opensLaterToday &&
          status.openMinutes != null) {
        final d = _deltaMinutes(nowM, status.openMinutes!);
        if (d > 0 && d <= thresholdMinutes) return true;
      }

      return false;
    }
  }
