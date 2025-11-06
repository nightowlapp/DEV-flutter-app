import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../repositories/venues/venue_media_repository.dart';
import '../../services/media_existence.dart';

final venueMediaRepositoryProvider = Provider<VenueMediaRepository>((ref) {
  return VenueMediaRepository(storage: FirebaseStorage.instance);
});

/// Fetch once with caching (in-repo TTL). Call .refresh() if you need a fresh read.
final venueMediaBundleProvider =
    FutureProvider.family<VenueMediaBundle, String>((ref, venueId) async {
  final repo = ref.watch(venueMediaRepositoryProvider);
  return repo.fetch(venueId);
});

// Public provider the UI will consume
final venueMediaProvider =
FutureProvider.family<VenueMediaHealth, String>((ref, venueId) async {
  final bundle = await ref.watch(venueMediaBundleProvider(venueId).future);
  return bundle.toHealth();
});

extension _BundleToHealth on VenueMediaBundle {
  VenueMediaHealth toHealth() {
    // Adjust field names if your bundle differs
    final cover = coverUrl ?? '';
    final logo  = logoUrl ?? '';
    final moods = moodImageUrls ?? const <String>[];

    return VenueMediaHealth(
      coverExists: cover.isNotEmpty,
      logoExists:  logo.isNotEmpty,
      moodCount:   moods.length,
      coverUrl:    cover.isNotEmpty ? cover : null,
      logoUrl:     logo.isNotEmpty ? logo : null,
    );
  }
}