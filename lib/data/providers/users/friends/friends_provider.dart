// lib/data/providers/friends/friends_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/users/user.dart' as model;
import '../../../firestore_paths.dart';
import '../../../repositories/users/user_repository.dart';
import '../../other_providers.dart' hide userRepositoryProvider;

final friendUidsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final fs = ref.watch(firestoreProvider);
  final me = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (me == null) return const Stream.empty();

  return fs
      .doc(DocumentPaths.user(me))
      .collection(DocumentPaths.friends)
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
