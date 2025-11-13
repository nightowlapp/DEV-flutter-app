/// Pure strings. No Firebase imports here.
class DocumentPaths {
  // Users
  //collections
  static const String users = 'users';
  static const String emblems = 'emblems';
  static const String partyStatusDays = 'party_status_days';
  static const String friends = 'friends';
  static const String locations = 'locations';
  static const String friendRequests = 'friend_requests';
  static const String incoming = 'incoming';
  static const String visits = 'visits';
  static const String usernames = 'usernames';

  // feedback
  static const String feedback = 'feedback';
  static const String appFeedback = 'app_feedback';
  static const String venueFeedback = 'venue_feedback';

  static String usernameDoc(String unameLower) => '$usernames/$unameLower';

  // fields
  static const preferredVenueTypes = 'preferred_venue_types';
  static const maxDistanceKm = 'max_distance_km';
  static const updatedAt = 'updated_at';
  static const homeCountry = 'home_country';
  static const homeTown = 'home_town';
  static const homeLocationLocked = 'home_location_locked';

  static const firstName = 'first_name';
  static const middleName = 'middle_name';
  static const lastName = 'last_name';
  static const phoneNumber = 'phone_number';
  static const userNameLower = 'user_name_lc';
  static const isVerified = 'is_verified';
  static const roles = 'roles';
  static const timestamp = 'timestamp';

  // Friend requests fields
  static const frFromUid = 'from_uid';
  static const frToUid = 'to_uid';

  // Location
  static String locationDoc(String uid) => '$locations/$uid';
  static const lastKnownLat = 'last_known_lat';
  static const lastKnownLon = 'last_known_lon';

  // Notifications
  static const notifications = 'notifications';
  static const notificationsQueue = 'queue';
  static const String fcmToken = 'fcm_tokens';
  static String senderNotifications(String senderId) =>
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

  /// New: user mood images nested under a venue
  static String userVenueMoodImagesDir(String userId, String venueId) =>
      '$userImages/$userId/$venueId';

  static String userVenueMoodImage(
      String userId, String venueId, String fileName) =>
      '${userVenueMoodImagesDir(userId, venueId)}/$fileName';

  // Venues
  static const venueImages = 'venue_images';
  static const venueCover = 'cover'; // .webp
  static const venueLogo = 'logo'; // .webp

  static String venueImage(String venueId, String fileName) =>
      '$venueImages/$venueId/$fileName';

  /// New: venue mood images folder
  static String venueMoodImagesDir(String venueId) =>
      '$venueImages/$venueId/mood_images';

  static String venueMoodImage(String venueId, String fileName) =>
      '${venueMoodImagesDir(venueId)}/$fileName';

  static const nightOwlImages = 'nightowl_images';
}
