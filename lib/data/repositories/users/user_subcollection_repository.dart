// data/user_social_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightowlcode/models/users/favorite_venue.dart';
import 'package:nightowlcode/models/users/liked_venue.dart';
import '../../../models/users/emblem.dart';
import '../../firestore_paths.dart';

class UserSocialRepository {
  final FirebaseFirestore _db;
  UserSocialRepository(this._db);

  // -------- Favorites --------
  CollectionReference<FavoriteVenue> _favoritesCol(String uid) => _db
      .collection(DocumentPaths.userSub(uid, DocumentPaths.favorites))
      .withConverter<FavoriteVenue>(
        fromFirestore: (snap, _) =>
            FavoriteVenue.fromJson(snap.data()!, snap.id),
        toFirestore: (f, _) => f.toJson(),
      );

  Future<void> addFavorite(String uid, String venueId) async {
    // created_at is set by the model; use merge:false to avoid re-writing created_at later
    final ref = _favoritesCol(uid).doc(venueId);
    await ref.set(FavoriteVenue(id: venueId), SetOptions(merge: false));
  }

  Future<void> removeFavorite(String uid, String venueId) =>
      _favoritesCol(uid).doc(venueId).delete();

  Stream<List<String>> watchFavoriteVenueIds(String uid) => _favoritesCol(uid)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((q) => q.docs.map((d) => d.id).toList());

  Future<bool> isFavorite(String uid, String venueId) async =>
      (await _favoritesCol(uid).doc(venueId).get()).exists;

  // -------- Likes --------
  CollectionReference<LikedVenue> _likesCol(String uid) => _db
      .collection(DocumentPaths.userSub(uid, DocumentPaths.likes))
      .withConverter<LikedVenue>(
        fromFirestore: (snap, _) => LikedVenue.fromJson(snap.data()!, snap.id),
        toFirestore: (l, _) => l.toJson(),
      );

  Future<void> likeVenue(String uid, String venueId) async {
    final ref = _likesCol(uid).doc(venueId);
    await ref.set(LikedVenue(id: venueId), SetOptions(merge: false));
  }

  Future<void> unlikeVenue(String uid, String venueId) =>
      _likesCol(uid).doc(venueId).delete();

  Stream<List<String>> watchLikedVenueIds(String uid) => _likesCol(uid)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((q) => q.docs.map((d) => d.id).toList());

  Future<bool> isLiked(String uid, String venueId) async =>
      (await _likesCol(uid).doc(venueId).get()).exists;

  // -------- Emblems --------
  CollectionReference<Emblem> _emblemsCol(String uid) => _db
      .collection(DocumentPaths.userSub(uid, DocumentPaths.emblems))
      .withConverter<Emblem>(
        fromFirestore: (snap, _) => Emblem.fromJson({
          'id': snap.id, // inject id from doc id
          ...?snap.data(),
        }),
        toFirestore: (a, _) => a.toJson()..remove('id'),
      );

  Future<void> upsertEmblem(String uid, Emblem a) async {
    final ref = _emblemsCol(uid).doc(a.id);
    await ref.set(a, SetOptions(merge: true));
  }

  Future<void> deleteEmblem(String uid, String emblemId) =>
      _emblemsCol(uid).doc(emblemId).delete();

  Stream<List<Emblem>> watchEmblem(String uid) => _emblemsCol(uid)
      .orderBy('unlocked_at', descending: true)
      .snapshots()
      .map((q) => q.docs.map((d) => d.data()).toList());
}

// --- cross-user collectionGroup helpers (client side) ---

/// Users who liked a venue (returns userIds).
Stream<List<String>> userIdsWhoLikedVenue(
    FirebaseFirestore db, String venueId) {
  return db
      .collectionGroup(DocumentPaths.likes)
      .where(FieldPath.documentId, isEqualTo: venueId)
      .snapshots()
      .map((q) => q.docs
          .map((d) => d.reference.parent.parent?.id)
          .whereType<String>()
          .toList());
}

/// Real-time count of favorites for a venue (downloads matching docs).
Stream<int> favoriteCount(FirebaseFirestore db, String venueId) {
  return db
      .collectionGroup(DocumentPaths.favorites)
      .where(FieldPath.documentId, isEqualTo: venueId)
      .snapshots()
      .map((q) => q.size);
}
