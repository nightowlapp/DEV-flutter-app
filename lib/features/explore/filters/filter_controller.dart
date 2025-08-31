// lib/features/explore/filters/filter_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'advanced_search_filter.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

final filtersProvider =
StateNotifierProvider.autoDispose<FilterController, AdvancedSearchFilter>(
      (ref) => FilterController(),
  name: 'filtersProvider',
);

class FilterController extends StateNotifier<AdvancedSearchFilter> {
  FilterController() : super(AdvancedSearchFilter.empty);

  void setOpenNow(bool v) => state = state.copyWith(openNowOnly: v);

  void setMinRating(double? r) =>
      state = state.copyWith(minRating: r, clearMinRating: r == null);

  void clearMinRating() => state = state.copyWith(clearMinRating: true);

  void setMaxDistanceKm(double? km) =>
      state = state.copyWith(maxDistanceKm: km, clearMaxDistance: km == null);

  void clearMaxDistance() => state = state.copyWith(clearMaxDistance: true);

  void toggleType(VenueType t) {
    final s = Set<VenueType>.from(state.types);
    if (s.contains(t)) {
      s.remove(t);
    } else {
      s.add(t);
    }
    state = state.copyWith(types: s);
  }

  void reset() => state = AdvancedSearchFilter.empty;
}
