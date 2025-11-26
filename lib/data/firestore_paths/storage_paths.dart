/// Firebase Storage paths. Pure strings only – no Firebase imports.
class StoragePaths {
  StoragePaths._();

  // ---- Users ----
  static const userImages = 'user_images';
  static const profilePicture = 'profile_picture';
  static const venueFeedback = 'venue_feedback';
  static const offerImages = 'offer_images';
  static const moodImages = 'mood_images';


  static String userImage(String userId, String fileName) =>
      '$userImages/$userId/$fileName';

  /// User mood images nested under a venue:
  /// `user_images/{userId}/{venueId}/{fileName}`
  static String userVenueMoodImagesDir(String userId, String venueId) =>
      '$userImages/$userId/$venueId';

  static String userVenueMoodImage(
      String userId,
      String venueId,
      String fileName,
      ) =>
      '${userVenueMoodImagesDir(userId, venueId)}/$fileName';

  // ---- Venues ----
  static const venueImages = 'venue_images';
  static const venueCover = 'cover'; // .webp
  static const venueLogo = 'logo'; // .webp

  static String venueImage(String venueId, String fileName) =>
      '$venueImages/$venueId/$fileName';

  /// `venue_images/{venueId}/mood_images/{fileName}`
  static String venueMoodImagesDir(String venueId) =>
      '$venueImages/$venueId/mood_images';

  static String venueMoodImage(String venueId, String fileName) =>
      '${venueMoodImagesDir(venueId)}/$fileName';

  // Misc app-wide images
  static const nightOwlImages = 'nightowl_images';
}
