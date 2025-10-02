// lib/models/friend_request.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequest {
  final String id;          // doc id
  final String fromUid;     // sender
  final String toUid;       // receiver (current user for incoming)
  final DateTime timestamp; // Firestore Timestamp

  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'from_uid': fromUid,
    'to_uid'  : toUid,
    'timestamp': FieldValue.serverTimestamp(),
  };

  static FriendRequest fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return FriendRequest(
      id: d.id,
      fromUid: (m['from_uid'] as String?) ?? '',
      toUid: (m['to_uid'] as String?) ?? '',
      timestamp: (m['timestamp'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
