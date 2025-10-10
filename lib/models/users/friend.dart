// TODO
import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  Friend({required this.userid, this.name = ''});

  final String userid;
  final String name;
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
