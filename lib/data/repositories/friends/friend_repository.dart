// lib/data/repositories/users/friends_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../firestore_paths/firestore_paths.dart';

class FriendsRepository {
  FriendsRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

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

    // 👇 this is the doc THEIR app listens to when deciding if they can see YOU
    final theirFriendDoc = _db
        .doc(UserDocumentPaths.doc(friendUid))
        .collection(UserDocumentPaths.friends)
        .doc(me);

    final batch = _db.batch();

    // My view: I mark them as close friend (for UI, etc.)
    batch.set(
      myFriendDoc,
      {
        FriendEdgeFields.isCloseFriend: isClose,
        UserDocumentPaths.updatedAt: FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Their view of me: they may / may not see me when my audience is closeFriends
    batch.set(
      theirFriendDoc,
      {
        'they_can_see_me': isClose, // 👈 key field
        UserDocumentPaths.updatedAt: FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }
  Future<void> setTheyCanSeeMe({
    required String friendUid,
    required bool allow,
  }) async {
    final me = _me;
    if (me == null) return;

    // Write into *their* friends/{me} doc:
    final theirFriendDoc = _db
        .doc(UserDocumentPaths.doc(friendUid))
        .collection(UserDocumentPaths.friends)
        .doc(me);

    await theirFriendDoc.set(
      {
        'they_can_see_me': allow,
        UserDocumentPaths.updatedAt: FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }


}
