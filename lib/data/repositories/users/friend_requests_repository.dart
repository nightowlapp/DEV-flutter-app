// lib/data/repositories/users/friend_requests_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import '../../../models/users/friend_request.dart';
import '../../firestore_paths/firestore_paths.dart';

enum FriendRequestSendResult {
  sent,
  notAuthenticated,
  selfRequest,
  alreadyFriends,
  alreadyPending,
  error,
}

class FriendRequestsRepository {
  FriendRequestsRepository(this._db, this._auth);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get _me => _auth.currentUser?.uid;

  Stream<List<FriendRequest>> incomingForMe() {
    final uid = _me;
    if (uid == null) return const Stream.empty();
    return _db
        .collection(FriendRequestDocumentPaths.collection)
        .where(FriendRequestDocumentPaths.toUid, isEqualTo: uid)
        .orderBy(FriendRequestDocumentPaths.timestamp, descending: true)
        .snapshots()
        .map((q) => q.docs.map(FriendRequest.fromDoc).toList());
  }

  Stream<List<FriendRequest>> outgoingFromMe() {
    final uid = _me;
    if (uid == null) return const Stream.empty();
    return _db
        .collection(FriendRequestDocumentPaths.collection)
        .where(FriendRequestDocumentPaths.fromUid, isEqualTo: uid)
        .orderBy(FriendRequestDocumentPaths.timestamp, descending: true)
        .snapshots()
        .map((q) => q.docs.map(FriendRequest.fromDoc).toList());
  }

  Future<FriendRequestSendResult> send({required String toUid}) async {
    try {
      final me = _me;
      if (me == null) return FriendRequestSendResult.notAuthenticated;
      if (me == toUid) return FriendRequestSendResult.selfRequest;

      // Already friends?
      final meFriendDoc = _db
          .doc(UserDocumentPaths.doc(me))
          .collection(UserDocumentPaths.friends)
          .doc(toUid);
      if ((await meFriendDoc.get()).exists) {
        return FriendRequestSendResult.alreadyFriends;
      }

      // Prevent duplicates both directions
      final a = _db
          .collection(FriendRequestDocumentPaths.collection)
          .doc('${me}_$toUid');
      final b = _db
          .collection(FriendRequestDocumentPaths.collection)
          .doc('${toUid}_$me');
      if ((await a.get()).exists || (await b.get()).exists) {
        return FriendRequestSendResult.alreadyPending;
      }

      await a.set({
        FriendRequestDocumentPaths.fromUid: me,
        FriendRequestDocumentPaths.toUid: toUid,
        FriendRequestDocumentPaths.timestamp: FieldValue.serverTimestamp(),
        FriendRequestDocumentPaths.status: FriendRequestStatus.pending.name,
      });

      return FriendRequestSendResult.sent;
    } catch (_) {
      return FriendRequestSendResult.error;
    }
  }

  Future<void> approve(FriendRequest req) async {
    final batch = _db.batch();

    final a = _db
        .doc(UserDocumentPaths.doc(req.toUid))
        .collection(UserDocumentPaths.friends)
        .doc(req.fromUid);
    final b = _db
        .doc(UserDocumentPaths.doc(req.fromUid))
        .collection(UserDocumentPaths.friends)
        .doc(req.toUid);

    final r1 = _db
        .collection(FriendRequestDocumentPaths.collection)
        .doc(req.id);
    final r2 = _db
        .collection(FriendRequestDocumentPaths.collection)
        .doc('${req.toUid}_${req.fromUid}');

    batch.set(a, {
      UserDocumentPaths.updatedAt: FieldValue.serverTimestamp(),
    });
    batch.set(b, {
      UserDocumentPaths.updatedAt: FieldValue.serverTimestamp(),
    });
    batch.delete(r1);
    batch.delete(r2);

    await batch.commit();
  }

  Future<void> reject(FriendRequest req) async {
    await _db
        .collection(FriendRequestDocumentPaths.collection)
        .doc(req.id)
        .delete();
  }
}
