import 'package:nightowlcode/shared/constants/enums.dart';

class AdvancedSearchFilter {
  final double? maxDistanceKm; // null = ignore
  final double? minRating; // 0–5, null = ignore
  final bool openNowOnly; // default true (from defaults provider)
  final Set<VenueType> types; // empty = all

  const AdvancedSearchFilter({
    this.maxDistanceKm,
    this.minRating,
    this.openNowOnly = false,
    this.types = const {},
  });

  AdvancedSearchFilter copyWith({
    double? maxDistanceKm,
    bool clearMaxDistance = false,
    double? minRating,
    bool clearMinRating = false,
    bool? openNowOnly,
    Set<VenueType>? types,
  }) {
    return AdvancedSearchFilter(
      maxDistanceKm:
          clearMaxDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      openNowOnly: openNowOnly ?? this.openNowOnly,
      types: types ?? this.types,
    );
  }

  static const empty = AdvancedSearchFilter();
}
