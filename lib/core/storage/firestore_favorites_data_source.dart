// lib/core/storage/firestore_favorites_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightowlcode/data/firestore_paths/firestore_paths.dart';
import '../../data/repositories/venues/favorites_repository.dart';

class FirestoreFavoritesDataSource implements FavoritesDataSource {
  FirestoreFavoritesDataSource(this.db);
  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      db.collection(UserDocumentPaths.favoritesCollection(userId));

  @override
  Future<bool> isFavorite({
    required String userId,
    required String venueId,
  }) async {
    final doc = await _col(userId).doc(venueId).get();
    return doc.exists;
  }

  @override
  Future<void> addFavorite({
    required String userId,
    required String venueId,
  }) async {
    await _col(userId).doc(venueId).set(
      {
        FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> removeFavorite({
    required String userId,
    required String venueId,
  }) async {
    await _col(userId).doc(venueId).delete();
  }

  @override
  Future<int> countFavorites({required String userId, int? atMost}) async {
    final q = atMost != null ? _col(userId).limit(atMost) : _col(userId);
    final snap = await q.get();
    return snap.docs.length;
  }

  @override
  Stream<int> watchCount({required String userId}) {
    return _col(userId).snapshots().map((s) => s.size);
  }

  @override
  Stream<List<String>> watchFavoriteVenueIds({required String userId}) {
    return _col(userId)
        .orderBy(FirestoreFields.createdAt, descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toList());
  }
}
