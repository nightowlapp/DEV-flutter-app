// lib/data/providers/users/friend_suggestions_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/users/user.dart' as model;
import '../../firestore_paths.dart';
import 'find_friends_providers.dart';
import 'friends_provider.dart';
import 'sorted_friends_provider.dart';

final userSearchQueryProvider = StateProvider<String>((_) => '');

final suggestedUsersProvider = StreamProvider<List<model.User>>((ref) {
  final me = ref.watch(authUserIdProvider);
  final q = ref.watch(userSearchQueryProvider);
  final db = FirebaseFirestore.instance;

  final friends = ref.watch(friendUidsProvider).maybeWhen(
    data: (ids) => ids.toSet(),
    orElse: () => <String>{},
  );
  final incoming = ref.watch(incomingFriendRequestsProvider).maybeWhen(
    data: (l) => l.map((e) => e.fromUid).toSet(),
    orElse: () => <String>{},
  );
  final outgoing = ref.watch(outgoingFriendRequestsProvider).maybeWhen(
    data: (l) => l.map((e) => e.toUid).toSet(),
    orElse: () => <String>{},
  );

  if (me == null) return const Stream.empty();

  Query<Map<String, dynamic>> base = db.collection(DocumentPaths.users);

  if (q.trim().length >= 2) {
    final s = q.trim().toLowerCase();
    base = base
        .orderBy(DocumentPaths.userNameLower) // 'user_name_lc'
        .startAt([s])
        .endAt(['$s\uf8ff'])
        .limit(25);
  } else {
    base = base.orderBy('created_at', descending: true).limit(25);
  }

  return base.snapshots().map((snap) {
    final users = snap.docs.map((d) {
      final data = d.data();
      return model.User.fromJson({'id': d.id, ...data});
    }).where((u) {
      if (u.id == me) return false;
      if (friends.contains(u.id)) return false;
      if (incoming.contains(u.id)) return false;
      if (outgoing.contains(u.id)) return false;
      return true;
    }).toList();

    return users;
  });
});
