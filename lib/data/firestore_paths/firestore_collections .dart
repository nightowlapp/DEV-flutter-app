// lib/data/firestore_paths/firestore_collections.dart

/// Pure strings. No Firebase imports here.
class FirestoreCollections {
  FirestoreCollections._();

  // all collections
  static const String emblems = 'emblems';
  static const String events = 'events';
  static const String feedback = 'feedback';
  static const String friendRequests = 'friend_requests';
  static const String locations = 'locations';
  static const notifications = 'notifications';
  static const tags = 'tags';
  static const String usernames = 'usernames';
  static const venues = 'venues';
  static const String users = 'users';

  static const String friends = 'friends';
  static const String closeFriends = 'close_friends';

  // live people count (shared name for Firestore + RTDB)
  static const String liveCounts = 'live_counts';
}
/// Very common field names reused across multiple collections.
class FirestoreFields {
  FirestoreFields._();

  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
  static const timestamp = 'timestamp';

  static const male = 'male';
  static const female = 'female';
  static const other = 'other';

  static const isVerified = 'is_verified';
}

class UsernameDocumentPaths {
  UsernameDocumentPaths._();

  static const collection = FirestoreCollections.usernames;

  /// Doc id is the lowercase username.
  static String doc(String usernameLower) => '$collection/$usernameLower';

  // If you also store fields inside the doc.
  static const userId = 'user_id';
  static const userNameLower = 'user_name_lc';
}

class TagDocumentPaths {
  TagDocumentPaths._();

  static const collection = FirestoreCollections.tags;

  static String doc(String tagId) => '$collection/$tagId';
}

class NotificationDocumentPaths {
  NotificationDocumentPaths._();

  static const collection = FirestoreCollections.notifications;

  /// Subcollection name holding the queue per sender/user.
  static const queue = 'queue';

  static String senderQueue(String senderId) => '$collection/$senderId/$queue';
}

class LocationDocumentPaths {
  LocationDocumentPaths._();

  static const collection = FirestoreCollections.locations;

  static String doc(String userId) => '$collection/$userId';

  static const lastKnownLat = 'last_known_lat';
  static const lastKnownLon = 'last_known_lon';
  static const timestamp = FirestoreFields.timestamp;
}

class FriendRequestDocumentPaths {
  FriendRequestDocumentPaths._();

  static const collection = FirestoreCollections.friendRequests;

  static String doc(String requestId) => '$collection/$requestId';

  // Fields
  static const fromUid = 'from_uid';
  static const toUid = 'to_uid';
  static const status = 'status';
  static const timestamp = FirestoreFields.timestamp;
}

class FeedbackDocumentPaths {
  FeedbackDocumentPaths._();

  static const collection = FirestoreCollections.feedback;

  static String doc(String uid) => '$collection/$uid';

  static const appFeedback = 'app_feedback';
  static const venueFeedback = 'venue_feedback';
  static const crashes = 'crashes';
  static const venueTags = 'tags';

  static const message = 'message';
  static const createdAt = FirestoreFields.createdAt;

  static const venueId = 'venue_id';
  static const category = 'category';

  // Tag suggestion fields
  static const tagId = 'tag_id';
  static const isApplied = 'is_applied';

  // Crash
  static const error = 'error';
  static const errorString = 'error_string';
}

class EmblemDocumentPaths {
  EmblemDocumentPaths._();

  static const collection = FirestoreCollections.emblems;

  static String doc(String emblemId) => '$collection/$emblemId';
}

class LiveCountDocumentPaths {
  LiveCountDocumentPaths._();

  static const collection = FirestoreCollections.liveCounts;

  static String doc(String venueId) => '$collection/$venueId';

  static const count = 'count';
}

class VisitDocumentPaths {
  VisitDocumentPaths._();

  static const collection = 'visits';

  static String collectionForUser(String uid) =>
      '${FirestoreCollections.users}/$uid/$collection';

  // fields
  static const venueId = 'venue_id';
  static const enteredAt = 'entered_at';
  static const exitedAt = 'exited_at';
  static const source = 'source';
}

/// Paths + fields for party status day + entries subcollections.
///
/// users/{uid}/party_status_days/{dayId}/entries/{entryId}
class PartyStatusDayDocumentPaths {
  PartyStatusDayDocumentPaths._();

  static const collection = 'party_status_days';
  static const entries = 'entries';

  static String collectionForUser(String uid) =>
      '${FirestoreCollections.users}/$uid/$collection';

  static String entriesCollection(String uid, String dayId) =>
      '${collectionForUser(uid)}/$dayId/$entries';

  static String entryDoc(String uid, String dayId, String entryId) =>
      '${entriesCollection(uid, dayId)}/$entryId';
}

class PartyStatusEntryDocumentPaths {
  PartyStatusEntryDocumentPaths._();

  // These live under:
  // users/{uid}/party_status_days/{dayId}/entries/{entryId}

  static const partyStatus = 'party_status';
  static const change = 'change';
  static const createdAt = FirestoreFields.createdAt;
  static const location = 'location';
  static const accuracy = 'accuracy';
}

class FriendEdgeFields {
  FriendEdgeFields._();

  static const iCanSeeThem = 'i_can_see_them';
  static const isCloseFriend = 'is_close_friend';
}
