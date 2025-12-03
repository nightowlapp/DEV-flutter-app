// Level system: DRY, SoC, scalable.
// - Call LevelLogic.progress(totalXp) to get level/xp state.
// - Default curve: easy to 20, harder to 30, brutal 31+.

import 'dart:math' as math;

/// Abstraction for "XP needed to go from level L -> L+1".
abstract class LevelCurve {
  /// Level is 1-based (level 1 -> level 2).
  double deltaForLevel(int level);
}

/// Linear: base + (level-1) * increment
class LinearCurve implements LevelCurve {
  LinearCurve({required this.base, required this.increment})
      : assert(base > 0),
        assert(increment >= 0);
  final double base;
  final double increment;

  @override
  double deltaForLevel(int level) =>
      base + (level - 1).clamp(0, 1 << 30) * increment;
}

/// Exponential: base * growth^(level-1)
class ExponentialCurve implements LevelCurve {
  ExponentialCurve({required this.base, required this.growth})
      : assert(base > 0),
        assert(growth >= 1.0);
  final double base;
  final double growth;

  @override
  double deltaForLevel(int level) =>
      base * (level <= 1 ? 1.0 : math.pow(growth, (level - 1))).toDouble();
}

/// Explicit per-level list (index 0 = level 1, 1 = level 2, ...)
class CustomCurve implements LevelCurve {
  CustomCurve(this.perLevel) : assert(perLevel.isNotEmpty);
  final List<double> perLevel;

  @override
  double deltaForLevel(int level) {
    final i = (level - 1);
    return perLevel[i.clamp(0, perLevel.length - 1)];
  }
}

/// Power curve for steeper mid/late ramps.
class PowerCurve implements LevelCurve {
  PowerCurve({required this.start, required this.scale, required this.exponent})
      : assert(exponent > 1);
  final double start; // XP for local L1 in this segment
  final double scale; // ramp rate
  final double exponent; // 1.6–2.6 typical

  @override
  double deltaForLevel(int localLevel) {
    final n = (localLevel - 1).clamp(0, 1 << 30);
    return start + scale * math.pow(n, exponent).toDouble();
  }
}

/// Piecewise helper types
class CurveSegment {
  const CurveSegment({required this.start, this.end, required this.curve});
  final int start; // inclusive
  final int? end; // inclusive; null = infinity
  final LevelCurve curve;

  bool contains(int level) => level >= start && (end == null || level <= end!);
  int local(int level) => level - start + 1;
}

class PiecewiseCurve implements LevelCurve {
  PiecewiseCurve(List<CurveSegment> segments)
      : assert(segments.isNotEmpty),
        _segments =
            (List.of(segments)..sort((a, b) => a.start.compareTo(b.start))) {
    assert(_segments.first.start == 1, 'First segment must start at level 1');
  }
  final List<CurveSegment> _segments;

  @override
  double deltaForLevel(int level) {
    final seg = _segments.firstWhere(
      (s) => s.contains(level),
      orElse: () => _segments.last,
    );
    return seg.curve.deltaForLevel(seg.local(level));
  }
}

class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.xpIntoLevel,
    required this.xpForLevel,
    required this.totalXp,
  });

  final int level; // current level (1-based)
  final double xpIntoLevel; // XP earned within this level
  final double xpForLevel; // XP needed to complete this level
  final double totalXp; // total lifetime XP

  double get progress01 =>
      xpForLevel <= 0 ? 1.0 : (xpIntoLevel / xpForLevel).clamp(0.0, 1.0);
  double get xpToNext => (xpForLevel - xpIntoLevel).clamp(0.0, double.infinity);
}

class LevelLogic {
  // === CONFIG ===

  // Default: Easy → 20, harder → 30, very hard 31+.
  static LevelCurve _curve = PiecewiseCurve([
    // L1–L20: cheap, slightly rising
    CurveSegment(
      start: 1,
      end: 20,
      curve: LinearCurve(base: 25, increment: 15), // 25,27,29,...
    ),
    // L21–L30: noticeable ramp
    CurveSegment(
      start: 21,
      end: 30,
      curve: PowerCurve(start: 60, scale: 6, exponent: 1.8),
    ),
    // L31+: brutal
    CurveSegment(
      start: 31,
      end: null, // infinity
      curve: ExponentialCurve(base: 120, growth: 1.22),
    ),
  ]);

  /// Getter/setter so changing the curve resets caches.
  static LevelCurve get curve => _curve;
  static set curve(LevelCurve c) {
    _curve = c;
    _cumulativeAtLevelStart
      ..clear()
      ..[1] = 0.0;
  }

  // Optional: cap levels (e.g., if you have finite content). null = infinite.
  static int? maxLevel;

  // Cache cumulative XP at level starts for speed.
  // level 1 starts at 0 XP.
  static final Map<int, double> _cumulativeAtLevelStart = {1: 0.0};

  /// Total XP required to reach the *start* of [level].
  /// (Level 1 start = 0)
  static double cumulativeXpToReachLevel(int level) {
    if (level <= 1) return 0.0;
    final target = maxLevel == null ? level : level.clamp(1, maxLevel!);
    // Fill cache up to target
    for (int l = 2; l <= target; l++) {
      if (_cumulativeAtLevelStart.containsKey(l)) continue;
      final prev = _cumulativeAtLevelStart[l - 1]!;
      _cumulativeAtLevelStart[l] = prev + curve.deltaForLevel(l - 1);
    }
    return _cumulativeAtLevelStart[target]!;
  }

  /// Find current level from [totalXp].
  /// Returns at least level 1. If [maxLevel] is set, clamps to it.
  static int levelFromTotalXp(double totalXp) {
    if (totalXp <= 0) return 1;
    int low = 1;
    int high = 2;

    // Grow upper bound until we surpass totalXp or hit maxLevel
    while (true) {
      final startHigh = cumulativeXpToReachLevel(high);
      final endHigh = startHigh + curve.deltaForLevel(high);
      final capped = maxLevel != null && high >= maxLevel!;
      if (totalXp < endHigh || capped) break;
      low = high;
      high = (high * 2).clamp(1, maxLevel ?? (1 << 30));
      if (high == low) break;
    }

    // Binary search between low..high
    int ans = 1;
    while (low <= high) {
      final mid = low + ((high - low) >> 1);
      final start = cumulativeXpToReachLevel(mid);
      final end = start + curve.deltaForLevel(mid);
      if (totalXp >= end) {
        ans = mid + 1;
        low = mid + 1;
      } else if (totalXp < start) {
        high = mid - 1;
      } else {
        ans = mid;
        break;
      }
    }

    if (maxLevel != null) ans = ans.clamp(1, maxLevel!) as int;
    return ans < 1 ? 1 : ans;
  }

  /// Full progress snapshot from [totalXp].
  static LevelProgress progress(double totalXp) {
    final lvl = levelFromTotalXp(totalXp);
    final start = cumulativeXpToReachLevel(lvl);
    final need = curve.deltaForLevel(lvl);
    final into = (totalXp - start).clamp(0.0, need);
    return LevelProgress(
      level: lvl,
      xpIntoLevel: into,
      xpForLevel: need,
      totalXp: totalXp,
    );
  }

  // === Convenience methods ===

  /// Total XP needed to complete the *current* level.
  static double calculateThisLevelTotalXp({
    required double currentXp,
    required int currentLevel,
  }) {
    return curve.deltaForLevel(currentLevel);
  }

  /// XP the user has *within* the current level.
  static double calculateUserXpThisLevel({
    required double currentXp,
    required int currentLevel,
  }) {
    final start = cumulativeXpToReachLevel(currentLevel);
    return (currentXp - start).clamp(0.0, curve.deltaForLevel(currentLevel));
  }

  // === XP reward helpers ===
  // Visits:
  // - Each visit: +5 XP flat.
  // - Time bonus: +1 XP per *completed* 2 hours at the venue (rounded down).
  //   e.g. 4.6h -> floor(4.6 / 2) = 2 → +2 XP.
  // - Repeat-visit bonus per venue: +[visitNumberForVenue] XP
  //   (5th visit to the same venue => +5 XP from this part).

  /// Flat XP awarded for any visit.
  static const int visitFlatXp = 5;

  /// XP per completed 2 hours at venue.
  static const int visitXpPerTwoHours = 1;

  /// XP from just "being there": 5 flat + 1 per completed 2h block.
  ///
  /// Examples:
  /// - 0.5h stay -> 5 XP
  /// - 4.6h stay -> 7 XP (5 base + floor(4.6 / 2) = 2)
  /// - 5.9h stay -> 7 XP (5 base + floor(5.9 / 2) = 2)
  static int xpFromVisitDuration(Duration stayDuration) {
    if (stayDuration <= Duration.zero) return visitFlatXp;

    final minutes = stayDuration.inMinutes;
    final completedTwoHourBlocks = minutes ~/ (2 * 60); // 120 minutes
    final timeBonus = completedTwoHourBlocks * visitXpPerTwoHours;

    return visitFlatXp + timeBonus;
  }

  /// Full XP for a venue visit.
  ///
  /// [stayDuration]  – time between enter and exit.
  /// [visitNumberForVenue] – 1-based index for this venue
  ///                        (1 = first time, 5 = 5th visit, etc.).
  ///
  /// Formula:
  ///   5 (flat)
  /// + floor(hours / 2)  (time bonus)
  /// + visitNumberForVenue (repeat-visit bonus)
  ///
  /// Example, 5th visit, 4.6h:
  ///   5 (flat) + 2 (time) + 5 (5th visit) = 12 XP.
  static int xpForVenueVisit({
    required Duration stayDuration,
    required int visitNumberForVenue,
  }) {
    final safeVisitNumber = visitNumberForVenue < 1 ? 1 : visitNumberForVenue;
    final baseAndTime = xpFromVisitDuration(stayDuration);
    return baseAndTime + safeVisitNumber;
  }
}
