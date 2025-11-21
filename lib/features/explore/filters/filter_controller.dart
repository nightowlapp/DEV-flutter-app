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
  // Use the same prefs the ranker uses so defaults stay in sync.
  final prefsAv = ref.watch(mePrefsAvProvider); // AsyncValue<UserPrefs>
  final prefs = prefsAv.asData?.value;

  return AdvancedSearchFilter(
    openNowOnly: true,
    maxDistanceKm: prefs?.maxDistanceKm, // may be null while prefs load
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
    final ctrl = FilterController(defaults);

    // If prefs/defaults change after the controller was created,
    // keep defaults (and untouched state) in sync.
    ref.listen<AdvancedSearchFilter>(
      _defaultFiltersProvider,
          (previous, next) {
        ctrl.updateDefaults(next);

        // If user hasn’t changed filters yet (state == old defaults),
        // move the state to the new defaults.
        if (previous == null || ctrl.state.isSameAs(previous)) {
          ctrl.state = next;
        }
      },
    );

    return ctrl;
  },
  name: 'filtersProvider',
);

/// True when current filters differ from defaults.
final filtersActiveProvider = Provider.autoDispose<bool>((ref) {
  final current = ref.watch(filtersProvider);
  final defaults = ref.watch(_defaultFiltersProvider);
  return !current.isSameAs(defaults);
});

/// Public view of defaults (for labels / comparisons).
final filterDefaultsProvider =
Provider.autoDispose<AdvancedSearchFilter>((ref) {
  return ref.watch(_defaultFiltersProvider);
});

class FilterController extends StateNotifier<AdvancedSearchFilter> {
  FilterController(this._defaults) : super(_defaults);

  AdvancedSearchFilter _defaults;

  void setOpenNow(bool v) => state = state.copyWith(openNowOnly: v);

  void setVerifiedOnly(bool v) => state = state.copyWith(verifiedOnly: v);

  void setMinRating(double? r) =>
      state = state.copyWith(minRating: r, clearMinRating: r == null);

  void clearMinRating() => state = state.copyWith(clearMinRating: true);

  // Now takes a non-null km (we use clearMaxDistance for "default")
  void setMaxDistanceKm(double km) =>
      state = state.copyWith(maxDistanceKm: km, clearMaxDistance: false);

  void clearMaxDistance() =>
      state = state.copyWith(clearMaxDistance: true);

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

  /// Called when prefs/defaults change.
  void updateDefaults(AdvancedSearchFilter d) {
    _defaults = d;
  }
}
