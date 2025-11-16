// lib/data/providers/users/friends/active_friends_count_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

import '../sorted_friends_provider.dart';
import '../user_providers.dart'; // userByUidProvider

/// Per-user reactive flag, driven by the same user stream as the status ring.
final isFriendActiveProvider = Provider.family<bool, String>((ref, uid) {
  final userAsync = ref.watch(userByUidProvider(uid));

  return userAsync.maybeWhen(
    data: (u) {
      if (u == null) return false;
      final status = u.currentPartyStatus;
      // Active = anything except still_planning & recovering
      return status != PartyStatusTypes.still_planning &&
          status != PartyStatusTypes.recovering;
    },
    orElse: () => false,
  );
});

/// Reactive total:
/// - Rebuilds when the friends list changes (added/removed).
/// - Rebuilds when ANY friend's user doc changes (status, etc.).
final activeFriendsCountProvider = Provider<int>((ref) {
  final friends = ref.watch(sortedFriendsProvider);

  var count = 0;
  for (final u in friends) {
    final isActive = ref.watch(isFriendActiveProvider(u.id));
    if (isActive) count++;
  }
  return count;
});
