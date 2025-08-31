// lib/shared/utility/venue_ranker.dart
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/distance.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/features/explore/utility/venue_ranker_prefs.dart';

import '../../../data/services/media_existence.dart';

typedef NowInTz = DateTime Function(String? tzid);

// ---------- Helpers / data types ----------
class DistanceBand {
  final int maxMeters; // <= this distance
  final int points;    // award these points
  const DistanceBand(this.maxMeters, this.points);
}

class Threshold {
  final int min;    // >= this value
  final int points; // award these points
  const Threshold(this.min, this.points);
}

class ScoreItem {
  final String label;
  final int points;
  const ScoreItem(this.label, this.points);
}

class ScoreResult {
  final int total;
  final List<ScoreItem> items;
  const ScoreResult(this.total, this.items);
}

// ========== TUNABLE RULES (all knobs in one place) ===========================
class PointRules {
  // --------- Global behavior ---------
  /// If true: venues that are NOT open now are pushed to the bottom (huge penalty).
  final bool showOnlyOpenNow;

  /// Prefer user’s types first (others sink far below via a single large penalty).
  final bool preferPreferredTypesFirst;
  final int nonPreferredTypePenalty; // must be very negative to always rank below

  // --------- Rating ---------
  /// e.g. 4.6★ -> round(4.6 * 2) = 9 points
  final int ratingPerStar;

  /// Extra points based on rating volume (kept for flexibility)
  final List<Threshold> ratingCountTiers;

  // --------- Distance ---------
  /// Points by distance (nearest first).
  final List<DistanceBand> distanceBands;

  /// If true: anything beyond user's max distance gets a massive drop.
  final bool hardCutBeyondMaxDistance;

  /// If not hard-cutting: penalty when beyond max distance (keeps them below inside-range).
  final int beyondMaxDistancePenalty;

  /// When party status is “strict”, we boost nearby and punish far.
  final Set<PartyStatusTypes> strictDistanceStatuses;
  final double strictDistanceMultiplier;     // multiply awarded band points
  final int strictBeyondMaxDistancePenalty;  // stronger penalty when strict

  // --------- Open status ---------
  final int openNowPoints;
  final int openTodayPoints; // used only if showOnlyOpenNow == false

  // --------- Media ---------
  final int hasCoverPoints;
  final int hasMoodPoints;
  final int hasLogoPoints; //TODo

  final int hasCornersPoints;
  final int hasCityPoints; // TODO more points more complete.

  // final int hasVisitorsPoints; // TODO more points more current visitors.
  // final int hasTagsPoints; //TODO

  // --------- Popularity (exact formula you wanted) ---------
  /// points = floor( clamp(favs*2, 0..200) + clamp(likes*1.2, 0..200) ) / popBucket
  /// With defaults → max raw=400 → /25 => 16 pts (capped by popMaxPoints).
  final double popLikesWeight; // 1.2
  final double popFavsWeight;  // 2.0
  final int popLikesCap;       // 200
  final int popFavsCap;        // 200
  final int popBucket;         // 25 raw per point
  final int popMaxPoints;      // cap

  // --------- Trust ---------
  final int verifiedPoints;

  // --------- Personalization ---------
  /// Add points if user age >= venue (effective) restriction.
  final int ageFitPoints;

  /// Apply only when user age is below restriction.  (Women get 1-year grace)
  final int ageTooHighPenalty;

  /// Optional nudge by party status (kept for easy tweaks)
  final Map<PartyStatusTypes, int> partyStatusPoints;

  const PointRules({
    // Global
    this.showOnlyOpenNow = true, // ✅ default: show open now
    this.preferPreferredTypesFirst = true,
    this.nonPreferredTypePenalty = -10000,

    // Rating
    this.ratingPerStar = 2,
    this.ratingCountTiers = const[
      Threshold(10, 2),
      Threshold(50, 4),
      Threshold(150, 8),
      Threshold(250, 12),
      Threshold(500, 16),
    ],

    // Distance (bands are additive, only the first matching band applies)
    this.distanceBands = const[
      DistanceBand(1000, 10),   // <= 1 km  : +10
      DistanceBand(2000, 8),    // <= 2 km  : +8
      DistanceBand(4000, 5),    // <= 4 km  : +5
      DistanceBand(10000, 3),   // <= 10 km : +3
      // > 10km → 0 by default (or penalty if beyond user max)
    ],
    this.hardCutBeyondMaxDistance = false, // ✅ outside maxDistance sinks below inside
    this.beyondMaxDistancePenalty = -20,

    // Strict distance when certain party statuses (e.g. planning/recovering)
    this.strictDistanceStatuses = const { PartyStatusTypes.still_planning },
    this.strictDistanceMultiplier = 1.5,     // boost near bands
    this.strictBeyondMaxDistancePenalty = -40, // punish far even harder

    // Open status
    this.openNowPoints = 10,
    this.openTodayPoints = 5,

    // Media
    this.hasCoverPoints = 12,
    this.hasMoodPoints = 8,
    this.hasLogoPoints = 6,

    this.hasCornersPoints = 4,
    this.hasCityPoints = 2,

    // Popularity
    this.popLikesWeight = 1.2,
    this.popFavsWeight = 2.0,
    this.popLikesCap = 200,
    this.popFavsCap = 200,
    this.popBucket = 25,
    this.popMaxPoints = 16,

    // Trust
    this.verifiedPoints = 20,

    // Personalization (effective age check; women have 1-year grace)
    this.ageFitPoints = 10,
    this.ageTooHighPenalty = -20,

    // Party status nudges (optional)
    this.partyStatusPoints = const {
      // PartyStatusTypes.still_planning: 1, // example
    },
  });

  PointRules copyWith({
    bool? showOnlyOpenNow,
    bool? preferPreferredTypesFirst,
    int? nonPreferredTypePenalty,
    int? ratingPerStar,
    List<Threshold>? ratingCountTiers,
    List<DistanceBand>? distanceBands,
    bool? hardCutBeyondMaxDistance,
    int? beyondMaxDistancePenalty,
    Set<PartyStatusTypes>? strictDistanceStatuses,
    double? strictDistanceMultiplier,
    int? strictBeyondMaxDistancePenalty,
    int? openNowPoints,
    int? openTodayPoints,
    int? hasCoverPoints,
    int? hasMoodPoints,
    double? popLikesWeight,
    double? popFavsWeight,
    int? popLikesCap,
    int? popFavsCap,
    int? popBucket,
    int? popMaxPoints,
    int? verifiedPoints,
    int? ageFitPoints,
    int? ageTooHighPenalty,
    Map<PartyStatusTypes, int>? partyStatusPoints,
  }) {
    return PointRules(
      showOnlyOpenNow: showOnlyOpenNow ?? this.showOnlyOpenNow,
      preferPreferredTypesFirst:
      preferPreferredTypesFirst ?? this.preferPreferredTypesFirst,
      nonPreferredTypePenalty:
      nonPreferredTypePenalty ?? this.nonPreferredTypePenalty,
      ratingPerStar: ratingPerStar ?? this.ratingPerStar,
      ratingCountTiers: ratingCountTiers ?? this.ratingCountTiers,
      distanceBands: distanceBands ?? this.distanceBands,
      hardCutBeyondMaxDistance:
      hardCutBeyondMaxDistance ?? this.hardCutBeyondMaxDistance,
      beyondMaxDistancePenalty:
      beyondMaxDistancePenalty ?? this.beyondMaxDistancePenalty,
      strictDistanceStatuses:
      strictDistanceStatuses ?? this.strictDistanceStatuses,
      strictDistanceMultiplier:
      strictDistanceMultiplier ?? this.strictDistanceMultiplier,
      strictBeyondMaxDistancePenalty:
      strictBeyondMaxDistancePenalty ?? this.strictBeyondMaxDistancePenalty,
      openNowPoints: openNowPoints ?? this.openNowPoints,
      openTodayPoints: openTodayPoints ?? this.openTodayPoints,
      hasCoverPoints: hasCoverPoints ?? this.hasCoverPoints,
      hasMoodPoints: hasMoodPoints ?? this.hasMoodPoints,
      hasLogoPoints: hasLogoPoints ?? this.hasLogoPoints,
      hasCornersPoints: hasCornersPoints ?? this.hasCornersPoints,
      hasCityPoints: hasCityPoints ?? this.hasCityPoints,
      popLikesWeight: popLikesWeight ?? this.popLikesWeight,
      popFavsWeight: popFavsWeight ?? this.popFavsWeight,
      popLikesCap: popLikesCap ?? this.popLikesCap,
      popFavsCap: popFavsCap ?? this.popFavsCap,
      popBucket: popBucket ?? this.popBucket,
      popMaxPoints: popMaxPoints ?? this.popMaxPoints,
      verifiedPoints: verifiedPoints ?? this.verifiedPoints,
      ageFitPoints: ageFitPoints ?? this.ageFitPoints,
      ageTooHighPenalty: ageTooHighPenalty ?? this.ageTooHighPenalty,
      partyStatusPoints: partyStatusPoints ?? this.partyStatusPoints,
    );
  }
}

// ========== RANKER ===========================================================
class VenueRanker {
  const VenueRanker({
    this.rules = const PointRules(),
    this.prefs,
    this.nowInTz,
  });

  static const int _DROP = -100000; // huge negative to force bottom

  final PointRules rules;
  final UserPrefs? prefs; // age, preferred types, maxDistanceKm, partyStatus, gender
  final NowInTz? nowInTz;

  // Public: Highest total first.
  List<Venue> sort(List<Venue> venues, {LatLng? userLocation, Map<String, VenueMediaHealth>? media,}) {
    final xs = List<Venue>.from(venues);
    xs.sort((a, b) {
      final sa = score(a, userLocation: userLocation, media: media).total;
      final sb = score(b, userLocation: userLocation, media: media).total; // ✅ pass media
      final cmp = sb.compareTo(sa);
      if (cmp != 0) return cmp;

        // Tie-breakers: rating → ratingCount → distance
        final ar = (a.rating ?? 0).compareTo(b.rating ?? 0);
        if (ar != 0) return -ar;
        final ac = a.ratingCount.compareTo(b.ratingCount);
        if (ac != 0) return -ac;

        final da = _metersFrom(userLocation, a.entry);
        final db = _metersFrom(userLocation, b.entry);
        return da.compareTo(db);
      }
    );
    return xs;
  }

  // Public: full breakdown for debugging/tuning
  ScoreResult score(Venue v, {LatLng? userLocation,   Map<String, VenueMediaHealth>? media,}) {
    final items = <ScoreItem>[];
    int total = 0;

    final now = (nowInTz != null) ? nowInTz!(v.timeZoneId) : DateTime.now();
    final isOpen = v.isOpenNow(now);
    final isOpenToday = v.isOpenToday(now);

    // 1) OPEN NOW gate (configurable)
    if (rules.showOnlyOpenNow && !isOpen) {
      // push to bottom; still return a trace to explain why
      return ScoreResult(_DROP, [const ScoreItem('closed_now', _DROP)]);
    }

    // 2) Preferred type first (if configured)
    if (prefs != null && rules.preferPreferredTypesFirst) {
      final isPreferred = prefs!.preferredTypes.contains(v.type);
      if (!isPreferred) {
        total += rules.nonPreferredTypePenalty;
        items.add(ScoreItem('nonPreferredType(${v.type.name})', rules.nonPreferredTypePenalty));
      }
    }

    // 3) Rating
    final rating = (v.rating ?? 0).clamp(0, 5);
    final ratingPts = (rating * rules.ratingPerStar).round();
    total += ratingPts;
    items.add(ScoreItem('rating(${rating.toStringAsFixed(1)}★)', ratingPts));

    final rcPts = _pointsForThreshold(v.ratingCount, rules.ratingCountTiers);
    if (rcPts != 0) {
      total += rcPts;
      items.add(ScoreItem('ratingCount(${v.ratingCount})', rcPts));
    }

    // 4) Distance (with “strict” mode support)
    final meters = _metersFrom(userLocation, v.entry);
    final strict = prefs != null && rules.strictDistanceStatuses.contains(prefs!.partyStatus);
    final distPts = _pointsForDistance(meters, prefs?.maxDistanceKm, strict: strict);
    total += distPts;
    items.add(ScoreItem('distance(${meters.round()}m${strict ? ',strict' : ''})', distPts));

    // 5) Open status points (only if not forcing open-now)
    if (!rules.showOnlyOpenNow) {
      if (isOpen) {
        total += rules.openNowPoints;
        items.add(ScoreItem('openNow', rules.openNowPoints));
      }
      else if (isOpenToday) {
        total += rules.openTodayPoints;
        items.add(ScoreItem('openToday', rules.openTodayPoints));
      }
    }

    // 6) Media — STRICT: only if we have a probe entry AND it says it exists.
    final mh = media?[v.id];
    if (mh != null) {
      if (mh.coverExists) {
        total += rules.hasCoverPoints;
        items.add(ScoreItem('hasCover', rules.hasCoverPoints));
      }
      if (mh.moodCount > 0) {
        total += rules.hasMoodPoints;
        items.add(ScoreItem('hasMood(${mh.moodCount})', rules.hasMoodPoints));
      }
      if (mh.logoExists) {
        total += rules.hasLogoPoints;
        items.add(ScoreItem('hasLogo', rules.hasLogoPoints));
      }
    }
// else: no probe result → no points, by design



    if (v.corners.isNotEmpty) {
      items.add(ScoreItem('hasCorners', rules.hasCornersPoints));
    }

    // 7) Popularity (likes & favs only, clamped, bucketed)
    final popPts = _popularityPoints(v.likeCount, v.favoriteCount);
    if (popPts != 0) {
      total += popPts;
      items.add(ScoreItem('popularity(likes=${v.likeCount}, favs=${v.favoriteCount})', popPts));
    }

    // 8) Verified
    if (v.isVerified) {
      total += rules.verifiedPoints;
      items.add(ScoreItem('verified', rules.verifiedPoints));
    }

    // 9) Personalization
    if (prefs != null) {
      // Effective age restriction (not default)
      final effAge = v.effectiveAgeRestriction(now);
      final uAge = prefs!.age;
      final gender = prefs!.gender;

      if (uAge >= effAge) {
        total += rules.ageFitPoints;
        items.add(ScoreItem('ageFit($effAge+)', rules.ageFitPoints));
      }
      else {
        final diff = effAge - uAge; // how many years too young
        // Women get 1-year grace
        final hasGrace = (gender == Gender.female) && (diff == 1);
        if (hasGrace) {
          total += rules.ageFitPoints; // treat as fit with grace
          items.add(ScoreItem('ageGraceFemale($effAge+)', rules.ageFitPoints));
        }
        else {
          total += rules.ageTooHighPenalty;
          items.add(ScoreItem('ageTooHigh($effAge+)', rules.ageTooHighPenalty));
        }
      }

      // Optional party status nudge
      final partyPts = rules.partyStatusPoints[prefs!.partyStatus] ?? 0;
      if (partyPts != 0) {
        total += partyPts;
        items.add(ScoreItem('party(${prefs!.partyStatus.name})', partyPts));
      }
    }

    return ScoreResult(total, items);
  }

  // ---------- internals ----------
  int _pointsForThreshold(int value, List<Threshold> tiers) {
    int best = 0;
    for (final t in tiers) {
      if (value >= t.min) best = t.points;
    }
    return best;
  }

  int _pointsForDistance(double meters, double? userMaxKm, {required bool strict}) {
    // Inside user max distance → award nearest matching band points
    // Beyond → penalty (or drop) so anything inside outranks anything outside.
    final maxMeters = (userMaxKm != null && userMaxKm > 0) ? userMaxKm * 1000 : null;

    // Beyond max distance handling
    if (maxMeters != null && meters > maxMeters) {
      if (rules.hardCutBeyondMaxDistance) {
        return _DROP; // force to bottom
      }
      // softer: a penalty (harsher if strict)
      return strict ? rules.strictBeyondMaxDistancePenalty : rules.beyondMaxDistancePenalty;
    }

    // Award the first band matched
    for (final band in rules.distanceBands) {
      if (meters <= band.maxMeters) {
        if (strict) {
          // boost nearby when strict (ceil to keep it integer)
          return (band.points * rules.strictDistanceMultiplier).ceil();
        }
        return band.points;
      }
    }
    return 0; // farther than last band (but still within user's max)
  }

  int _popularityPoints(int likes, int favs) {
    final r = rules;
    final likesScore = (likes * r.popLikesWeight).clamp(0, r.popLikesCap.toDouble());
    final favsScore = (favs * r.popFavsWeight ).clamp(0, r.popFavsCap.toDouble());
    final raw = likesScore + favsScore;     // 0..400 by default
    int pts = (raw / r.popBucket).floor(); // 400/25 -> 16
    if (pts > r.popMaxPoints) pts = r.popMaxPoints;
    if (pts < 0) pts = 0;
    return pts;
  }

  double _metersFrom(LatLng? user, LatLng to) =>
  (user == null) ? 1e12 : Distance.metersLatLng(user, to);
}
