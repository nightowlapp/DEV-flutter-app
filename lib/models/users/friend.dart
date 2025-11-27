// TODO
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:nightowlcode/shared/constants/enums.dart';

class FriendProfile {
  final String uid;
  final String? displayName;
  final PartyStatusTypes? partyStatus;
  final String? photoUrl; // 👈 NEW

  const FriendProfile({
    required this.uid,
    this.displayName,
    this.partyStatus,
    this.photoUrl,
  });

  static PartyStatusTypes? _parseStatus(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return PartyStatusTypes.values.firstWhere(
            (e) => e.name == raw,
        orElse: () => PartyStatusTypes.still_planning,
      );
    } catch (_) {
      return null;
    }
  }

  /// Adjust field names to match your users collection.
  factory FriendProfile.fromUserDoc(String uid, Map<String, dynamic> data) {
    final name = ( data['user_name'] ?? data['display_name'] ??
        data['name']) as String?;

    final statusRaw =  data['current_party_status'] as String? ??
        data['party_status'] as String?;

    final photo = (data['profile_picture_url'] ??
        data['photoUrl'] ??
        data['photo_url']) as String?; // 👈 tweak to your schema

    return FriendProfile(
      uid: uid,
      displayName: name,
      partyStatus: _parseStatus(statusRaw),
      photoUrl: photo,
    );
  }
}



class Friend {
  Friend(this.isGoodFriend, {required this.userid, this.name = ''});

  final String userid;
  final String name;
  final bool isGoodFriend;
  // final GeoPoint currentLocation; // = locations/{userid}/{live_location}
}
//TODO make below instead.

class FriendEdge {
  final String uid; // friend user id (doc id)
  final bool iCanSeeThem; // I can see their live location
  final bool theyCanSeeMe; // they can see mine
  final DateTime createdAt; // from Firestore 'timestamp'

  const FriendEdge({
    required this.uid,
    this.iCanSeeThem = true,
    this.theyCanSeeMe = true,
    required this.createdAt,
  });

  /// Use this when creating the edge (stores a real Firestore Timestamp)
  Map<String, dynamic> toCreateJson() => {
    'i_can_see_them': iCanSeeThem,
    'they_can_see_me': theyCanSeeMe,
    'created_at': FieldValue.serverTimestamp(), // ✅ Timestamp
  };

  /// Use this for updates (doesn't touch created_at)
  Map<String, dynamic> toUpdateJson() => {
    'i_can_see_them': iCanSeeThem,
    'they_can_see_me': theyCanSeeMe,
  };

  static FriendEdge from(String uid, Map<String, dynamic> m) => FriendEdge(
    uid: uid,
    iCanSeeThem: (m['i_can_see_them'] as bool?) ?? true,
    theyCanSeeMe: (m['they_can_see_me'] as bool?) ?? true,
    createdAt: (m['created_at'] as Timestamp?)?.toDate() ??
      DateTime.fromMillisecondsSinceEpoch(0),
  );
}
