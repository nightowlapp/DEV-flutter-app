// lib/features/map/presentation/selected_venue_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/other_providers.dart'; // allVenuesStreamProvider
import '../../../models/venues/venue.dart';

/// Holds the currently tapped/selected venue id (null = none).
final selectedVenueIdProvider = StateProvider<String?>((_) => null);

/// Resolves the full Venue object for the selected id.
final selectedVenueProvider = Provider<Venue?>((ref) {
  final selectedId = ref.watch(selectedVenueIdProvider);
  if (selectedId == null) return null;

  final venuesAv = ref.watch(allVenuesStreamProvider);
  return venuesAv.maybeWhen(
    data: (list) {
      for (final v in list) {
        if (v.id == selectedId) return v;
      }
      return null;
    },
    orElse: () => null,
  );
});
