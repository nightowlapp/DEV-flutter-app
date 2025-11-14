import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/users/user.dart' as model;

import '../../../../shared/party_priority.dart';
import '../../../repositories/users/user_repository.dart';
import 'friends_provider.dart';
import '../sorted_friends_provider.dart' show authUserIdProvider;
import 'friend_request_provider.dart';

// Search text (local UI state)
final findFriendsSearchProvider = StateProvider.autoDispose<String>((_) => '');

// Raw suggestions from Firestore (prefix search on user_name_lc)
final _rawSuggestionsProvider =
StreamProvider.autoDispose<List<model.User>>((ref) {
  final repo = ref.read(userRepositoryProvider);
  final q = ref.watch(findFriendsSearchProvider);
  return repo.searchUsersByUsernameLc(query: q, limit: 40);
});

// Outgoing requests (to exclude those you've already requested)
final outgoingFriendRequestsProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.read(friendRequestsRepositoryProvider);
  return repo.outgoingFromMe();
});

// Incoming requests (to exclude senders)
final incomingFriendRequestsProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.read(friendRequestsRepositoryProvider);
  return repo.incomingForMe();
});

/// Final suggestions = raw – me – friends – incoming/outgoing requests,
/// then sort by (1) has profile picture, (2) party status priority, (3) username.
final findFriendsSuggestionsProvider =
Provider.autoDispose<AsyncValue<List<model.User>>>((ref) {
  final raw = ref.watch(_rawSuggestionsProvider);
  final me = ref.watch(authUserIdProvider);

  final friends = ref.watch(friendUidsProvider).maybeWhen(
    data: (ids) => ids.toSet(),
    orElse: () => <String>{},
  );

  final incoming = ref.watch(incomingFriendRequestsProvider).maybeWhen(
    data: (reqs) => reqs.map((r) => r.fromUid).toSet(),
    orElse: () => <String>{},
  );

  final outgoing = ref.watch(outgoingFriendRequestsProvider).maybeWhen(
    data: (reqs) => reqs.map((r) => r.toUid).toSet(),
    orElse: () => <String>{},
  );

  return raw.whenData((users) {
    final exclude = <String>{
      if (me != null) me,
      ...friends,
      ...incoming,
      ...outgoing,
    };

    final list = users.where((u) => !exclude.contains(u.id)).toList();

    list.sort((a, b) {
      final aPic = a.hasProfilePicture;
      final bPic = b.hasProfilePicture;
      if (aPic != bPic) return aPic ? -1 : 1;

      final pa = partyPriority(a.currentPartyStatus);
      final pb = partyPriority(b.currentPartyStatus);
      if (pa != pb) return pa.compareTo(pb);

      final an = a.userName.trim().toLowerCase();
      final bn = b.userName.trim().toLowerCase();
      if (an != bn) return an.compareTo(bn);

      return a.id.compareTo(b.id);
    });

    return list;
  });
});
