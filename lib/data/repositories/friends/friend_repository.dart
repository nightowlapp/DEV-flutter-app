// lib/data/repositories/users/friends_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../firestore_paths/firestore_paths.dart';

class FriendsRepository {
  FriendsRepository(this._db, this._auth, this._functions);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  String? get _me => _auth.currentUser?.uid;

  /// Toggle close-friend flag *from my perspective*.
  Future<void> setCloseFriend({
    required String friendUid,
    required bool isClose,
  }) async {
    final me = _me;
    if (me == null) return;

    final myFriendDoc = _db
        .doc(UserDocumentPaths.doc(me))
        .collection(UserDocumentPaths.friends)
        .doc(friendUid);

    await myFriendDoc.set(
      {
        FriendEdgeFields.isCloseFriend: isClose,
        UserDocumentPaths.updatedAt: FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// (For later) “This friend may / may not ever see my location”.
  /// Still only writes *my* doc.
  Future<void> setTheyCanSeeMe({
    required String friendUid,
    required bool allow,
  }) async {
    final me = _me;
    if (me == null) return;

    final myFriendDoc = _db
        .doc(UserDocumentPaths.doc(me))
        .collection(UserDocumentPaths.friends)
        .doc(friendUid);

    await myFriendDoc.set(
      {
        'they_can_see_me': allow,
        UserDocumentPaths.updatedAt: FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> unfriend(String friendUid) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw Exception('Not authenticated');
    }

    final callable = _functions.httpsCallable('unfriendUser');
    await callable.call(<String, dynamic>{
      'targetUid': friendUid,
    });
  }
}


