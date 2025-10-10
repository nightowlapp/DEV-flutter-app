/// Pure strings. No Firebase imports here.
class DocumentPaths {
  //Users
  static const users = 'users';
  static const String emblems = 'emblems';
  static const String partyStatusDays = 'party_status_days';
  static const String locations = 'locations';
  static const String friendRequests = 'friend_requests';
  static const String incoming = 'incoming';
  static const String visits = 'visits';

  // Notifications
  static const notifications = 'notifications'; // parent
  static const notificationsQueue = 'queue'; // subcollection name
  static const String fcmToken = 'fcm_tokens';

  static String senderNotifications(
          String senderId) => // senderid == venueid/nightowl
      '$notifications/$senderId/$notificationsQueue';

  static String user(String id) => '$users/$id';
  static String userSub(String id, String sub) => '$users/$id/$sub';

  // live count
  static const liveCounts = 'live_counts';
  static const count = 'count';

  static String liveCount(String id) => '$liveCounts/$id';

  // venues
  static const venues = 'venues';
  static const tags = 'tags';

  static String tag(String id) => '$tags/$id';
  static String venue(String id) => '$venues/$id';
  static String venueSub(String id, String sub) => '$venues/$id/$sub';

  // Mix
  static const String favorites = 'favorites';
  static const String likes = 'likes';
  static const String entries = 'entries';
}

class StoragePaths {
  // Users
  static const userImages = 'user_images';
  static const profilePicture = 'profile_picture';

  static String userImage(String userId, String fileName) =>
      '$userImages/$userId/$fileName';

  // Venues
  static const venueImages = 'venue_images';
  static const venueCover = 'cover'; // .webp
  static const venueLogo = 'logo'; // .webp

  static String venueImage(String venueId, String fileName) =>
      '$venueImages/$venueId/$fileName';

  static const nightOwlImages = 'nightowl_images';
}
