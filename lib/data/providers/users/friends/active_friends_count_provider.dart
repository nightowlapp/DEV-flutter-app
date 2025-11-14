// lib/data/providers/users/friends/active_friends_count_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

import '../sorted_friends_provider.dart';

/// Reactive total; rebuilds whenever the friends list or their statuses change.
final activeFriendsCountProvider = Provider<int>((ref) {
  final friends = ref.watch(sortedFriendsProvider);

  var count = 0;
  for (final u in friends) {  
    final status = u.currentPartyStatus;
    // "Active" = anything except still_planning & recovering
    if (status != PartyStatusTypes.still_planning &&
        status != PartyStatusTypes.recovering) {
      count++;
    }
  }

  return count;
});
