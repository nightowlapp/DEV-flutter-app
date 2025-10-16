/// Pure strings. No Firebase imports here.
class DocumentPaths {
  //Users
  //collections
  static const users = 'users';
  static const String emblems = 'emblems';
  static const String partyStatusDays = 'party_status_days';
  static const String locations = 'locations';
  static const String friendRequests = 'friend_requests';
  static const String incoming = 'incoming';
  static const String visits = 'visits';
  static const usernames = 'usernames';

  static String usernameDoc(String unameLower) => '$usernames/$unameLower'; //TODO usernames should be typed how the user wants. NightOwl of all forms should be reseved and only could be made if admin or in database itself.

  //fields
  static const preferredVenueTypes = 'preferred_venue_types';
  static const maxDistanceKm = 'max_distance_km';
  static const updatedAt = 'updated_at';
  static const homeCountry = 'home_country';      // iso2, lowercase ("dk")
  static const homeTown = 'home_town';         // lowercase ("copenhagen")
  static const homeLocationLocked = 'home_location_locked'; // bool

  static const firstName = 'first_name';
  static const middleName = 'middle_name';
  static const lastName = 'last_name';
  static const phoneNumber = 'phone_number';        // map {e164, iso2, calling_code}
  static const userNameLower = 'user_name_lc';
  static const isVerified = 'is_verified';
  static const roles = 'roles';

  // Location
  static String locationDoc(String uid) => '$locations/$uid';

  static const lastKnownLat = 'last_known_lat'; // double
  static const lastKnownLon = 'last_known_lon'; // double

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
