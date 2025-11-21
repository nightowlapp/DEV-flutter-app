// lib/features/explore/filters/filter_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

import '../../../data/providers/users/user_providers.dart';
import 'advanced_search_filter.dart';

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
    verifiedOnly: false,
    minAgeRestriction: null,
    maxEntryPrice: null,
    includeTags: const {},
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

/// True when current filters differ from defaults.
final filtersActiveProvider = Provider.autoDispose<bool>((ref) {
  final current = ref.watch(filtersProvider);
  final defaults = ref.watch(_defaultFiltersProvider);
  // either "not equal" or a simpler rule: hasAnyRestriction
  return !current.isSameAs(defaults);
});

class FilterController extends StateNotifier<AdvancedSearchFilter> {
  FilterController(this._defaults) : super(_defaults);

  AdvancedSearchFilter _defaults;

  void setOpenNow(bool v) => state = state.copyWith(openNowOnly: v);

  void setVerifiedOnly(bool v) => state = state.copyWith(verifiedOnly: v);

  void setMinRating(double? r) =>
      state = state.copyWith(minRating: r, clearMinRating: r == null);

  void clearMinRating() => state = state.copyWith(clearMinRating: true);

  void setMaxDistanceKm(double? km) =>
      state = state.copyWith(maxDistanceKm: km, clearMaxDistance: km == null);

  void clearMaxDistance() => state = state.copyWith(clearMaxDistance: true);

  void setMinAgeRestriction(int? age) =>
      state = state.copyWith(minAgeRestriction: age, clearMinAge: age == null);

  void clearMinAgeRestriction() =>
      state = state.copyWith(clearMinAge: true);

  void setMaxEntryPrice(double? price) => state = state.copyWith(
      maxEntryPrice: price, clearMaxEntryPrice: price == null);

  void clearMaxEntryPrice() =>
      state = state.copyWith(clearMaxEntryPrice: true);

  void toggleType(VenueType t) {
    final s = Set<VenueType>.from(state.types);
    s.contains(t) ? s.remove(t) : s.add(t);
    state = state.copyWith(types: s);
  }

  void toggleTag(String tagId) {
    final s = Set<String>.from(state.includeTags);
    s.contains(tagId) ? s.remove(tagId) : s.add(tagId);
    state = state.copyWith(includeTags: s);
  }

  /// Reset back to the **current** defaults.
  void reset() => state = _defaults;

  /// If you want defaults to update when prefs arrive later,
  /// expose this (optional).
  void updateDefaults(AdvancedSearchFilter d) {
    _defaults = d;
  }
}
