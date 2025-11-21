// lib/features/explore/filters/advanced_search_filter.dart
import 'package:nightowlcode/shared/constants/enums.dart';

class AdvancedSearchFilter {
  final double? maxDistanceKm; // null = ignore
  final double? minRating;     // 0–5, null = ignore //TODO want smart to use venues.lowestrated.round
  final bool openNowOnly;      // default true (from defaults provider)
  final Set<VenueType> types;  // empty = all

  // Optional extra knobs you can start using when you add UI:
  final bool verifiedOnly;        // only verified venues
  final int? minAgeRestriction;   // e.g. 21 -> only 21+ venues
  final double? maxEntryPrice;    // null = ignore
  final Set<String> includeTags;  // venue.tagids must contain at least one

  const AdvancedSearchFilter({
    this.maxDistanceKm,
    this.minRating,
    this.openNowOnly = false,
    this.types = const {},
    this.verifiedOnly = false,
    this.minAgeRestriction,
    this.maxEntryPrice,
    this.includeTags = const {},
  });

  AdvancedSearchFilter copyWith({
    double? maxDistanceKm,
    bool clearMaxDistance = false,
    double? minRating,
    bool clearMinRating = false,
    bool? openNowOnly,
    Set<VenueType>? types,
    bool? verifiedOnly,
    int? minAgeRestriction,
    bool clearMinAge = false,
    double? maxEntryPrice,
    bool clearMaxEntryPrice = false,
    Set<String>? includeTags,
    bool clearIncludeTags = false,
  }) {
    return AdvancedSearchFilter(
      maxDistanceKm:
      clearMaxDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      openNowOnly: openNowOnly ?? this.openNowOnly,
      types: types ?? this.types,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      minAgeRestriction:
      clearMinAge ? null : (minAgeRestriction ?? this.minAgeRestriction),
      maxEntryPrice: clearMaxEntryPrice
          ? null
          : (maxEntryPrice ?? this.maxEntryPrice),
      includeTags: clearIncludeTags ? const {} : (includeTags ?? this.includeTags),
    );
  }

  static const empty = AdvancedSearchFilter();

  // ---- helpers for "are filters active?" ----

  bool isSameAs(AdvancedSearchFilter other) {
    return maxDistanceKm == other.maxDistanceKm &&
        minRating == other.minRating &&
        openNowOnly == other.openNowOnly &&
        verifiedOnly == other.verifiedOnly &&
        minAgeRestriction == other.minAgeRestriction &&
        maxEntryPrice == other.maxEntryPrice &&
        _setEquals(types, other.types) &&
        _setEquals(includeTags, other.includeTags);
  }

  bool get hasAnyRestriction =>
      maxDistanceKm != null ||
          minRating != null ||
          openNowOnly ||
          verifiedOnly ||
          minAgeRestriction != null ||
          maxEntryPrice != null ||
          types.isNotEmpty ||
          includeTags.isNotEmpty;

  static bool _setEquals<E>(Set<E> a, Set<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }
}
