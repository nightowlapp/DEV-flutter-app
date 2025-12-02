// lib/data/providers/friends/friend_requests_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nightowlcode/features/social/utility/friend_requests_section.dart';
import '../../../../models/users/friend_request.dart';
import '../../../repositories/users/friend_requests_repository.dart';

final friendRequestsRepositoryProvider = Provider<FriendRequestsRepository>((ref) {
  return FriendRequestsRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

final incomingFriendRequestsProvider = StreamProvider<List<FriendRequest>>(
      (ref) => ref.watch(friendRequestsRepositoryProvider).incomingForMe(),
);

final outgoingFriendRequestsProvider = StreamProvider<List<FriendRequest>>(
      (ref) => ref.watch(friendRequestsRepositoryProvider).outgoingFromMe(),
);

final pendingRequestsCountProvider = Provider<int>((ref) {
  final list = ref.watch(incomingFriendRequestsProvider).maybeWhen(
    data: (v) => v.where((r) => r.statusIsPending).toList(),
    orElse: () => const <FriendRequest>[],
  );
  return list.length;
});
