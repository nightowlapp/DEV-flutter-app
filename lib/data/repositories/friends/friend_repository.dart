// TODO later according to CHAT ( FROM VENUEFRIENDREPOISTORY.Dart)
// Also Add mapfeed.

// lib/data/repositories/firestore/friends_repository_fs.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/users/friend.dart';
import '../map/map_repository.dart';

class FriendRepository implements AbstractFriendRepository {
  FriendRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  @override
  Stream<List<Friend>> watchFriends(Viewport vp) {
    final fiveMinAgo = DateTime.now().millisecondsSinceEpoch - 5 * 60 * 1000;
    return _db
        .collection('friends_locations') // TODO Call from path.
        .where('updated_at', isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(fiveMinAgo))
        .snapshots()
        .map((snap) {
      final out = <Friend>[];
      for (final friend in snap.docs) {
        final m = friend.data();
        final gp = m['position'];
        if (gp is! GeoPoint) continue;
        out.add(friend as Friend);
      }
      // TODO fix. Fetch Friend objects. Not Strings.
      return out;
    });
  }
}
