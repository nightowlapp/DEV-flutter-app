import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'advanced_search_filter.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import '../presentation/ranked_venues_controller.dart'; // for userPrefsProvider

/// Build defaults once from user prefs.
/// - openNowOnly = true
/// - maxDistanceKm = user's pref (if present)
/// - types = all (empty set = no restriction)
final _defaultFiltersProvider =
    Provider.autoDispose<AdvancedSearchFilter>((ref) {
  final prefs = ref.watch(userPrefsProvider);
  return AdvancedSearchFilter(
    openNowOnly: true,
    maxDistanceKm: prefs?.maxDistanceKm, // may be null if not loaded yet
    minRating: null,
    types: const {}, // empty == all
  );
});

final filtersProvider =
    StateNotifierProvider.autoDispose<FilterController, AdvancedSearchFilter>(
  (ref) {
    final defaults = ref.watch(_defaultFiltersProvider);
    return FilterController(defaults);
  },
  name: 'filtersProvider',
);

class FilterController extends StateNotifier<AdvancedSearchFilter> {
  FilterController(this._defaults) : super(_defaults);

  AdvancedSearchFilter _defaults;

  void setOpenNow(bool v) => state = state.copyWith(openNowOnly: v);

  void setMinRating(double? r) =>
      state = state.copyWith(minRating: r, clearMinRating: r == null);

  void clearMinRating() => state = state.copyWith(clearMinRating: true);

  void setMaxDistanceKm(double? km) =>
      state = state.copyWith(maxDistanceKm: km, clearMaxDistance: km == null);

  void clearMaxDistance() => state = state.copyWith(clearMaxDistance: true);

  void toggleType(VenueType t) {
    final s = Set<VenueType>.from(state.types);
    s.contains(t) ? s.remove(t) : s.add(t);
    state = state.copyWith(types: s);
  }

  /// Reset back to the **current** defaults.
  void reset() => state = _defaults;

  /// If you want defaults to update when prefs arrive later,
  /// expose this (optional):
  void updateDefaults(AdvancedSearchFilter d) {
    _defaults = d;
  }
}
