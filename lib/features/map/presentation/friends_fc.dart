// lib/features/map/presentation/friends_fc.dart
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

import '../../../models/users/friend.dart';
import '../../../models/users/live_location.dart';

//TODO change at some point. NO need to run through all of them. Just friends.

String friendsToFeatureCollection(
  Map<String, LiveLocation> locations,
  Map<String, FriendProfile> profiles,
) {
  final features = <Map<String, dynamic>>[];

  locations.forEach((uid, loc) {
    final profile = profiles[uid];
    final displayName = profile?.displayName ?? uid;
    final partyStatus = profile?.partyStatus?.name ?? 'still_planning';
    debugPrint('$partyStatus !!!!!!!!!!!!');

    final avatarImageId = 'friend_avatar_${uid}_$partyStatus';

    final pretty = Utility.formatString(Utility.formatTimeAgo(loc.timestamp));

    final props = <String, dynamic>{
      'id': uid,
      'name': displayName,
      'party_status': partyStatus,
      'timestamp_pretty': pretty,
      'avatar_image_id': avatarImageId, // 👈 always set
    };

    features.add({
      'type': 'Feature',
      'id': uid,
      'properties': props,
      'geometry': {
        'type': 'Point',
        'coordinates': [loc.lng, loc.lat],
      },
    });
  });

  return jsonEncode({
    'type': 'FeatureCollection',
    'features': features,
  });
}
