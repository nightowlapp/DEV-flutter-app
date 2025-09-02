//TODO move all firestore related providers in here.


import '../core/storage/firestore_likes_data_source.dart';
import 'other_providers.dart';
import 'repositories/venues/like_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/services/like_store.dart';

// Choose data source (Firestore)
final likesDataSourceProvider = Provider<LikesDataSource>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirestoreLikesDataSource(db);
  // For local only: return LocalLikesDataSource();
});

final likesRepositoryProvider = Provider<LikesRepository>((ref) {
  return LikesRepository(ref.watch(likesDataSourceProvider));
});

/// One LikeStore per venueId. Auto-disposes when the widget subtree leaves.
/// Rebuilds when auth changes so it re-inits for new user.
final likeStoreProvider = ChangeNotifierProvider.family
    .autoDispose<LikeStore, String>((ref, venueId) {
  // Recreate store when auth state changes (ensures fresh init)
  ref.watch(authStateProvider);

  final repo = ref.watch(likesRepositoryProvider);
  String? getUserId() => ref.read(firebaseAuthProvider).currentUser?.uid;

  final store = LikeStore(
    entityId: venueId,
    getUserId: getUserId,
    repository: repo,
  );

  // Kick off initial load
  Future.microtask(store.init);

  return store;
});
