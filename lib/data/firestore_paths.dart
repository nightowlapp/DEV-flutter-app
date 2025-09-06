/// Pure strings. No Firebase imports here.
class DocumentPaths {
  //Users
  static const users = 'users';
  static const String achievements = 'achievements';
  static const String partyStatusDays = 'party_status_days';

  static String user(String id) => '$users/$id';
  static String userSub(String id, String sub) => '$users/$id/$sub';

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
  static const venueImages = 'venue_images';

  static const userImages = 'user_images';
  static const profilePicture = 'profile_picture';


  static const nightOwlImages = 'nightowl_images';

  static String venueImage(String venueId, String fileName) =>
  '$venueImages/$venueId/$fileName';

  static String userImage(String userId, String fileName) =>
  '$userImages/$userId/$fileName';
}
