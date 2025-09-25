import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../repositories/venues/venue_media_repository.dart';


final venueMediaRepositoryProvider = Provider<VenueMediaRepository>((ref) {
  return VenueMediaRepository(storage: FirebaseStorage.instance);
});

/// Fetch once with caching (in-repo TTL). Call .refresh() if you need a fresh read.
final venueMediaBundleProvider =
FutureProvider.family<VenueMediaBundle, String>((ref, venueId) async {
  final repo = ref.watch(venueMediaRepositoryProvider);
  return repo.fetch(venueId);
});
