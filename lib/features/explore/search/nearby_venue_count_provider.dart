// lib/features/explore/search/nearby_venue_count_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/utility/distance.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

import '../../../data/providers/users/user_providers.dart';
import '../../../data/services/location/location_providers.dart';
import '../ranking/explore_ranked_providers.dart';

// Fallback if prefs are not set yet.
const double _kDefaultMaxDistanceKm = 15;

final nearbyVenueCountProvider = Provider.autoDispose<int?>((ref) {
  // Ranked venues (already distance-gated a bit in exploreRankedVenuesProvider)
  final rankedAv = ref.watch(exploreRankedVenuesProvider);
  final List<Venue>? venues = rankedAv.asData?.value;

  // Latest user location
  final LatLng? userLoc = ref
      .watch(latLngSafeStreamProvider)
      .maybeWhen(data: (p) => p, orElse: () => null);

  // Max distance from prefs or default
  final double maxKm =
      (ref.watch(userPrefsProvider)?.maxDistanceKm ?? _kDefaultMaxDistanceKm)
          .toDouble();

  if (userLoc == null) return null; // still waiting on location
  if (venues == null || venues.isEmpty) return null;

  // If user explicitly sets <= 0 km, respect that and show 0
  if (maxKm <= 0) return 0;

  final maxMeters = maxKm * 1000.0;
  final now = DateTime.now();

  // Helper to count open venues within a given radius
  int _countWithin(double meters) {
    int count = 0;
    for (final v in venues) {
      if (!v.isOpenNow(now)) continue;
      if (Distance.metersLatLng(userLoc, v.entry) <= meters) {
        count++;
      }
    }
    return count;
  }

  // 1) Normal behavior: count open venues within maxKm
  int count = _countWithin(maxMeters);

  if (count > 0) {
    return count;
  }

  // 2) FINAL CHECK: if that yields 0, relax the "nearby" filter
  //    and count all open venues in the ranked pool (ignore distance).
  int relaxedCount = 0;
  for (final v in venues) {
    if (v.isOpenNow(now)) {
      relaxedCount++;
    }
  }

  return relaxedCount;
}, name: 'nearbyVenueCountProvider');
