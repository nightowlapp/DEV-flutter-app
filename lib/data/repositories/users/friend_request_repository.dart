// lib/data/repositories/friends/friend_requests_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nightowlcode/data/firestore_paths.dart';

import '../../../models/users/friend_request.dart';

class FriendRequestsRepository {
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  FriendRequestsRepository(this.db, this.auth);

  CollectionReference<Map<String, dynamic>> _incomingCol(String uid) => db
      .collection(DocumentPaths.friendRequests)
      .doc(uid)
      .collection(DocumentPaths.incoming);

  Stream<List<FriendRequest>> incomingForMe() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _incomingCol(uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(FriendRequest.fromDoc).toList());
  }

  Future<void> send({required String toUid}) async {
    final fromUid = auth.currentUser?.uid;
    if (fromUid == null || fromUid == toUid) return;

    await _incomingCol(toUid).add({
      'from_uid': fromUid,
      'to_uid': toUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approve(FriendRequest r) async {
    // TODO: write your friendship edge(s) here (both directions if needed)
    // e.g. /friends/{me}/list/{them} and /friends/{them}/list/{me}
    await _incomingCol(r.toUid).doc(r.id).delete();
  }

  Future<void> reject(FriendRequest r) async {
    await _incomingCol(r.toUid).doc(r.id).delete();
  }
}
