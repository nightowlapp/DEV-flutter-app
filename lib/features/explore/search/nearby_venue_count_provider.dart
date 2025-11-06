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
  // Ranked venues
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
  if (maxKm <= 0) return 0;

  final maxMeters = maxKm * 1000.0;
  int count = 0;
  for (final v in venues) {
    if (Distance.metersLatLng(userLoc, v.entry) <= maxMeters) count++;
  }
  return count;
}, name: 'nearbyVenueCountProvider');
