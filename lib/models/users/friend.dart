// lib/models/users/friend.dart

// TODO
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:nightowlcode/data/firestore_paths/user_paths.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

import '../../data/firestore_paths/firestore_collections .dart';

class FriendProfile {
  final String uid;
  final String? displayName;
  final PartyStatusTypes? partyStatus;
  final String? photoUrl;

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
    final name = (data[UserDocumentPaths.userName] ??
            data['display_name'] ?? // legacy / fallback
            data['name']) // legacy / fallback
        as String?;

    final statusRaw = data[UserDocumentPaths.currentPartyStatus] as String? ??
        data[PartyStatusEntryDocumentPaths.partyStatus] as String?;

    final photo = (data[UserDocumentPaths.profilePictureUrl] ??
            data['photoUrl'] ?? // legacy / fallback
            data['photo_url']) // legacy / fallback
        as String?; // 👈 tweak to your schema

    return FriendProfile(
      uid: uid,
      displayName: name,
      partyStatus: _parseStatus(statusRaw),
      photoUrl: photo,
    );
  }
}

//TODO make below instead.

class FriendEdge {
  final String uid; // friend user id (doc id)
  final bool iCanSeeThem; // I want to see their live location
  final bool isCloseFriend; // I classify them as close friend
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FriendEdge({
    required this.uid,
    this.iCanSeeThem = true,
    this.isCloseFriend = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Use this when creating the edge
  Map<String, dynamic> toCreateJson() => {
        FriendEdgeFields.iCanSeeThem: iCanSeeThem,
        FriendEdgeFields.isCloseFriend: isCloseFriend,
        FirestoreFields.createdAt: FieldValue.serverTimestamp(),
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      };

  /// Use this for updates (doesn't touch created_at)
  Map<String, dynamic> toUpdateJson() => {
        FriendEdgeFields.iCanSeeThem: iCanSeeThem,
        FriendEdgeFields.isCloseFriend: isCloseFriend,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      };

  static FriendEdge from(String uid, Map<String, dynamic> m) => FriendEdge(
        uid: uid,
        iCanSeeThem: (m[FriendEdgeFields.iCanSeeThem] as bool?) ?? true,
        isCloseFriend: (m[FriendEdgeFields.isCloseFriend] as bool?) ?? false,
        createdAt: (m[FirestoreFields.createdAt] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: (m[FirestoreFields.updatedAt] as Timestamp?)?.toDate(),
      );
}
