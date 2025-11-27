// lib/models/friend_request.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightowlcode/shared/constants/enums.dart'; // for FriendRequestStatus

class FriendRequest {
  final String id;          // "${fromUid}_${toUid}"
  final String fromUid;     // sender
  final String toUid;       // receiver
  final DateTime createdAt; // from Firestore "timestamp"
  final DateTime updatedAt;
  final FriendRequestStatus status;

  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.createdAt,
    required this.status,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'from_uid': fromUid,
    'to_uid': toUid,
    'timestamp': Timestamp.fromDate(createdAt),
    'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'status': status.name,
  };

  static FriendRequest fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};

    final createdAt =
      (m['timestamp'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0);

    final updatedAt =
      (m['updated_at'] as Timestamp?)?.toDate();

    final rawStatus = m['status'] as String?;
    final status = FriendRequestStatus.values.firstWhere(
      (s) => s.name == rawStatus,
      orElse: () => FriendRequestStatus.pending,
    );

    return FriendRequest(
      id: d.id,
      fromUid: (m['from_uid'] as String?) ?? '',
      toUid: (m['to_uid'] as String?) ?? '',
      createdAt: (m['created_at'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: (m['updated_at'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      status: status,
    );
  }
}
