// lib/data/repositories/venues/firestore_likes_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightowlcode/data/firestore_paths/firestore_paths.dart';

import '../../data/repositories/venues/like_repository.dart';

class FirestoreLikesDataSource implements LikesDataSource {
  FirestoreLikesDataSource(this.db);
  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> _likesCol(String userId) => db
      .collection(UserDocumentPaths.likesCollection(userId));

  @override
  Future<bool> isLiked({
    required String userId,
    required String entityId,
  }) async {
    final doc = await _likesCol(userId).doc(entityId).get();
    return doc.exists;
  }

  @override
  Future<void> like({
    required String userId,
    required String entityId,
  }) async {
    await _likesCol(userId).doc(entityId).set({
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> unlike({
    required String userId,
    required String entityId,
  }) async {
    await _likesCol(userId).doc(entityId).delete();
  }
}
