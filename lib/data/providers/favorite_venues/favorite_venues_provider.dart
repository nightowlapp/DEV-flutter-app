// lib/data/providers/favorite_venues_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/venues/venue.dart';
import '../../firestore_paths.dart';
import '../other_providers.dart';
import 'favorites_providers.dart';

/// Stream of venue IDs the user has favorited.
final favoriteVenueIdsProvider = StreamProvider<List<String>>((ref) {
  final auth = ref.watch(authStateProvider).value; // FirebaseAuth user?
  if (auth == null) return const Stream<List<String>>.empty();
  final repo = ref.watch(favoritesRepositoryProvider);
  return repo.watchFavoriteVenueIds(userId: auth.uid);
});

/// Helper to fetch venues by IDs (chunks of 10).
Future<List<Venue>> _fetchVenuesByIds(FirebaseFirestore db, List<String> ids) async {
  if (ids.isEmpty) return const [];
  const chunkSize = 10;

  final chunks = <List<String>>[];
  for (var i = 0; i < ids.length; i += chunkSize) {
    chunks.add(ids.sublist(i, i + chunkSize > ids.length ? ids.length : i + chunkSize));
  }

  final results = <Venue>[];

  for (final chunk in chunks) {
    final qs = await db
        .collection(DocumentPaths.venues)
        .where(FieldPath.documentId, whereIn: chunk)
        .get();

    for (final d in qs.docs) {
      final data = d.data() as Map<String, dynamic>; // <-- cast to Map
      results.add(Venue.fromJson(data, d.id));        // <-- pass 2 args
    }
  }

  // Keep the subcollection order (created_at desc) based on the original ids list
  final index = {for (var i = 0; i < ids.length; i++) ids[i]: i};
  results.sort((a, b) => (index[a.id] ?? 0).compareTo(index[b.id] ?? 0));
  return results;
}

/// Future of the actual Venue objects, recomputed whenever the IDs change.
final favoriteVenuesProvider = FutureProvider<List<Venue>>((ref) async {
  final idsAsync = await ref.watch(favoriteVenueIdsProvider.future);
  final db = ref.watch(firestoreProvider);
  return _fetchVenuesByIds(db, idsAsync);
});
