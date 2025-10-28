// lib/data/repositories/users/friend_requests_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/users/friend_request.dart';
import '../../firestore_paths.dart';

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
        .collection(DocumentPaths.friendRequests)
        .where(DocumentPaths.frToUid, isEqualTo: uid)
        .orderBy(DocumentPaths.timestamp, descending: true)
        .snapshots()
        .map((q) => q.docs.map(FriendRequest.fromDoc).toList());
  }

  Stream<List<FriendRequest>> outgoingFromMe() {
    final uid = _me;
    if (uid == null) return const Stream.empty();
    return _db
        .collection(DocumentPaths.friendRequests)
        .where(DocumentPaths.frFromUid, isEqualTo: uid)
        .orderBy(DocumentPaths.timestamp, descending: true)
        .snapshots()
        .map((q) => q.docs.map(FriendRequest.fromDoc).toList());
  }

  Future<FriendRequestSendResult> send({required String toUid}) async {
    try {
      final me = _me;
      if (me == null) return FriendRequestSendResult.notAuthenticated;
      if (me == toUid) return FriendRequestSendResult.selfRequest;

      // Already friends?
      final meFriendDoc =
      _db.doc(DocumentPaths.user(me)).collection(DocumentPaths.friends).doc(toUid);
      if ((await meFriendDoc.get()).exists) {
        return FriendRequestSendResult.alreadyFriends;
      }

      // Prevent duplicates both directions
      final a = _db.collection(DocumentPaths.friendRequests).doc('${me}_$toUid');
      final b = _db.collection(DocumentPaths.friendRequests).doc('${toUid}_$me');
      if ((await a.get()).exists || (await b.get()).exists) {
        return FriendRequestSendResult.alreadyPending;
      }

      await a.set({
        DocumentPaths.frFromUid: me,
        DocumentPaths.frToUid: toUid,
        DocumentPaths.timestamp: FieldValue.serverTimestamp(),
      });

      return FriendRequestSendResult.sent;
    } catch (_) {
      return FriendRequestSendResult.error;
    }
  }

  Future<void> approve(FriendRequest req) async {
    final batch = _db.batch();

    final a = _db
        .doc(DocumentPaths.user(req.toUid))
        .collection(DocumentPaths.friends)
        .doc(req.fromUid);
    final b = _db
        .doc(DocumentPaths.user(req.fromUid))
        .collection(DocumentPaths.friends)
        .doc(req.toUid);

    final r1 = _db.collection(DocumentPaths.friendRequests).doc(req.id);
    final r2 =
    _db.collection(DocumentPaths.friendRequests).doc('${req.toUid}_${req.fromUid}');

    batch.set(a, {DocumentPaths.updatedAt: FieldValue.serverTimestamp()});
    batch.set(b, {DocumentPaths.updatedAt: FieldValue.serverTimestamp()});
    batch.delete(r1);
    batch.delete(r2);

    await batch.commit();
  }

  Future<void> reject(FriendRequest req) async {
    await _db.collection(DocumentPaths.friendRequests).doc(req.id).delete();
  }
}
