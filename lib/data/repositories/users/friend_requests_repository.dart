// lib/data/repositories/users/friend_requests_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
        .snapshots()
        .map((q) {
      debugPrint('incomingForMe docs=${q.docs.length}');
      for (final d in q.docs) {
        debugPrint('incoming doc: ${d.id} -> ${d.data()}');
      }
      return q.docs.map(FriendRequest.fromDoc).toList();
    });
  }

  Stream<List<FriendRequest>> outgoingFromMe() {
    final uid = _me;
    if (uid == null) return const Stream.empty();

    return _db
        .collection(FriendRequestDocumentPaths.collection)
        .where(FriendRequestDocumentPaths.fromUid, isEqualTo: uid)
        .snapshots()
        .map((q) {
      debugPrint('outgoingFromMe docs=${q.docs.length}');
      for (final d in q.docs) {
        debugPrint('outgoing doc: ${d.id} -> ${d.data()}');
      }
      return q.docs.map(FriendRequest.fromDoc).toList();
    });
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
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        FirestoreFields.createdAt: FieldValue.serverTimestamp(),
        FriendRequestDocumentPaths.status: FriendRequestStatus.pending.name,
      });

      return FriendRequestSendResult.sent;
    } catch (_) {
      return FriendRequestSendResult.error;
    }
  }

  Future<void> approve(FriendRequest req) async {
    await _db
        .collection(FriendRequestDocumentPaths.collection)
        .doc(req.id)
        .update({
      FriendRequestDocumentPaths.status: FriendRequestStatus.accepted.name,
      UserDocumentPaths.updatedAt: FieldValue.serverTimestamp(),
    });
  }

  Future<void> reject(FriendRequest req) async {
    await _db
        .collection(FriendRequestDocumentPaths.collection)
        .doc(req.id)
        .update({
      FriendRequestDocumentPaths.status: FriendRequestStatus.rejected.name,
      UserDocumentPaths.updatedAt: FieldValue.serverTimestamp(),
    });
  }

  /// Cancel an outgoing request that *I* sent.
  /// We delete the doc so I can send again later if I want.
  Future<void> cancelOutgoing(FriendRequest req) async {
    await _db
        .collection(FriendRequestDocumentPaths.collection)
        .doc(req.id)
        .delete();
  }
}
