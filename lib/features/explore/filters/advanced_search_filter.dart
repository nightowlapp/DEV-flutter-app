// lib/features/explore/filters/advanced_search_filter.dart
import 'package:nightowlcode/shared/constants/enums.dart';

class AdvancedSearchFilter {
  /// Distance cap in **km** (null = ignore)
  final double? maxDistanceKm;

  /// Minimum star rating 0–5 (null = ignore)
  final double? minRating;

  /// Only venues open **now**
  final bool openNowOnly;

  /// Limit to these types (empty = all)
  final Set<VenueType> types;

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
      maxDistanceKm: clearMaxDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      openNowOnly: openNowOnly ?? this.openNowOnly,
      types: types ?? this.types,
    );
  }

  static const empty = AdvancedSearchFilter();
}
