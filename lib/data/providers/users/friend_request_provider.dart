// lib/data/providers/friends/friend_requests_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/users/friend_request.dart';
import '../../repositories/users/friend_request_repository.dart';

final friendRequestsRepositoryProvider = Provider<FriendRequestsRepository>((ref) {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  return FriendRequestsRepository(db, auth);
});

final incomingFriendRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  return ref.watch(friendRequestsRepositoryProvider).incomingForMe();
});

final incomingFriendRequestsCountProvider = Provider<int>((ref) {
  final list = ref.watch(incomingFriendRequestsProvider).maybeWhen(
    data: (v) => v,
    orElse: () => const <FriendRequest>[],
  );
  return list.length;
});
