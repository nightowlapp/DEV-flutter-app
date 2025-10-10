// lib/features/explore/presentation/nearby_venue_count_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/utility/distance.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

import '../../../data/providers/other_providers.dart';
import '../../../data/services/location/location_controller.dart';
import 'ranked_venues_controller.dart'; // rankedVenuesProvider + userPrefsProvider

// Fallback if prefs are not set yet.
const double _kDefaultMaxDistanceKm = 50;

final nearbyVenueCountProvider = Provider.autoDispose<int?>((ref) {
  // Ranked venues (already sorted and reactive)
  final ranked = ref.watch(rankedVenuesProvider);
  final state = ranked.asData?.value;

  // Prefer the controller's userLoc; if it's null, peek at raw location (optional).
  final LatLng? userLoc = state?.userLoc ??
      ref.watch(currentLatLngProvider).asData?.value; // safe fallback

  // Read max distance from prefs, fallback to default.
  final double maxKm =
      (ref.watch(userPrefsProvider)?.maxDistanceKm ?? _kDefaultMaxDistanceKm)
          .toDouble();

  if (userLoc == null) return null; // still waiting on location
  if (state == null || state.venues.isEmpty)
    return null; // venues not ready yet
  if (maxKm <= 0) return 0;

  final maxMeters = maxKm * 1000.0;
  int count = 0;
  for (final Venue v in state.venues) {
    if (Distance.metersLatLng(userLoc, v.entry) <= maxMeters) count++;
  }
  return count;
});
