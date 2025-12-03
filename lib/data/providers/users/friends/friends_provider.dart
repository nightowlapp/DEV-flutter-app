// lib/data/providers/friends/friends_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/users/user.dart' as model;
import '../../../../models/users/friend.dart';
import '../../../firestore_paths/firestore_paths.dart';
import '../../../repositories/friends/friend_repository.dart';
import '../../../repositories/users/user_repository.dart';
import '../../other_providers.dart' hide userRepositoryProvider;

class FriendCounts {
  final int total;
  final int closeFriends;

  const FriendCounts({
    required this.total,
    required this.closeFriends,
  });
}

final friendCountsProvider = StreamProvider<FriendCounts>((ref) {
  final fs = ref.watch(firestoreProvider);
  final me = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (me == null) return const Stream.empty();

  return fs
      .doc(UserDocumentPaths.doc(me))
      .collection(UserDocumentPaths.friends)
      .snapshots()
      .map((q) {
    int total = 0;
    int close = 0;

    for (final doc in q.docs) {
      total++;
      final data = doc.data();
      final isClose = (data[FriendEdgeFields.isCloseFriend] as bool?) ?? false;
      if (isClose) close++;
    }

    return FriendCounts(total: total, closeFriends: close);
  });
});

final friendUidsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final fs = ref.watch(firestoreProvider);
  final me = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (me == null) return const Stream.empty();

  return fs
      .doc(UserDocumentPaths.doc(me))
      .collection(UserDocumentPaths.friends)
      .snapshots()
      .map((q) => q.docs.map((d) => d.id).toList());
});

final friendsProvider = StreamProvider<List<model.User>>((ref) {
  final repo = ref.read(userRepositoryProvider);
  return ref.watch(friendUidsProvider.stream).asyncMap((ids) async {
    final users = await Future.wait(ids.map(repo.getById));
    return users.whereType<model.User>().toList();
  });
});

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

final friendEdgeWithUserProvider =
    StreamProvider.family<FriendEdge?, String>((ref, otherUid) {
  final auth = ref.watch(firebaseAuthProvider);
  final me = auth.currentUser;
  if (me == null) {
    return Stream.value(null);
  }

  final db = FirebaseFirestore.instance;

  return db
      .doc(UserDocumentPaths.doc(me.uid))
      .collection(UserDocumentPaths.friends)
      .doc(otherUid)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    final data = doc.data() ?? const <String, dynamic>{};
    return FriendEdge.from(doc.id, data);
  });
});
