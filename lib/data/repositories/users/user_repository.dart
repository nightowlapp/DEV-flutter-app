// data/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightowlcode/models/users/user.dart' as model;
import '../../firestore_paths.dart';

class UserRepository {
  UserRepository(FirebaseFirestore db)
      : _users = db.collection(DocumentPaths.users).withConverter<model.User>(
    fromFirestore: (snap, _) {
      final data = snap.data() ?? const <String, dynamic>{};
      // inject docId as 'id' for the Dart model; DO NOT store it
      return model.User.fromJson({'id': snap.id, ...data});
    },
    toFirestore: (u, _) => _userToFirestore(u),
  );

  final CollectionReference<model.User> _users;

  // --- Reads ---
  Stream<model.User?> watchById(String id) =>
      _users.doc(id).snapshots().map((s) => s.data());

  Future<model.User?> getById(String id) async =>
      (await _users.doc(id).get()).data();

  // --- Queries ---
  Future<bool> usernameAvailable(String userName) async {
    final q = await _users
        .where('user_name', isEqualTo: userName.trim())
        .limit(1)
        .get();
    return q.docs.isEmpty;
  }

  /// Users who have favorited [venueId], using collectionGroup('favorites')
  Stream<List<model.User>> byFavoriteVenue(String venueId) {
    final db = _users.firestore;

    // We used doc id == venueId in the favorites subcollection,
    // so we can query by documentId directly.
    final favoritesGroupQuery = db
        .collectionGroup(DocumentPaths.favorites)
        .where(FieldPath.documentId, isEqualTo: venueId);

    return favoritesGroupQuery.snapshots().asyncMap((q) async {
      final userIds = q.docs
          .map((d) => d.reference.parent.parent?.id)
          .whereType<String>()
          .toSet()
          .toList();

      if (userIds.isEmpty) return <model.User>[];

      // Fan-out reads; for large results consider chunking / index + in queries.
      final futures = userIds.map((uid) => _users.doc(uid).get());
      final snaps = await Future.wait(futures);

      return snaps
          .where((s) => s.data() != null)
          .map((s) => s.data()!)
          .toList();
    });
  }

  // --- Mutations ---
  Future<void> setUsername(String id, String userName) async {
    final ref = _users.doc(id);
    await ref.update({
      'user_name': userName.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markVerified(String id, bool isVerified) async {
    await _users.doc(id).update({
      'is_verified': isVerified,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> create(model.User u) async {
    final ref = _users.doc(u.id);
    final batch = ref.firestore.batch();
    batch.set(ref, u, SetOptions(merge: false)); // write all non-null fields
    batch.update(ref, {
      // authoritative timestamps from server
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> upsert(model.User u) async {
    final ref = _users.doc(u.id);
    final batch = ref.firestore.batch();
    batch.set(ref, u, SetOptions(merge: true));
    batch.update(ref, {'updated_at': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  Future<void> delete(String id) => _users.doc(id).delete();
}

Map<String, Object?> _userToFirestore(model.User u) {
  // Start from model JSON (snake_case keys).
  final json = Map<String, Object?>.from(u.toJson());

  // Ensure Firestore never stores the model id.
  json.remove('id');

  // Normalize
  json['email'] = u.email.trim().toLowerCase();
  json['user_name'] = u.userName.trim();

  // Convert date-ish fields to Timestamps for consistency
  json['birth_date'] = Timestamp.fromDate(u.birthDate);
  json['created_at'] = Timestamp.fromDate(u.createdAt);
  json['updated_at'] = Timestamp.fromDate(u.updatedAt);

  // Default the flag on write if someone forgot to set it
  json['is_verified'] = (json['is_verified'] as bool?) ?? false;

  // NOTE: favorites/likes/achievements are NOT stored on the user doc anymore.

  return json;
}

// Users who liked a venue:
Stream<List<String>> userIdsWhoLikedVenue(FirebaseFirestore db, String venueId) {
  return db
      .collectionGroup(DocumentPaths.likes)
      .where(FieldPath.documentId, isEqualTo: venueId)
      .snapshots()
      .map((q) => q.docs
      .map((d) => d.reference.parent.parent?.id)
      .whereType<String>()
      .toList());
}

// Count favorites for a venue:
Stream<int> favoriteCount(FirebaseFirestore db, String venueId) {
  return db
      .collectionGroup(DocumentPaths.favorites)
      .where(FieldPath.documentId, isEqualTo: venueId)
      .snapshots()
      .map((q) => q.size);
}

// Users with the most achievements: // TODO

// Users with the most xp/level: // TODO
