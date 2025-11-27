// lib/data/firestore_paths/user_paths.dart
import 'firestore_collections .dart';

/// Firestore paths & fields for the top-level `users` collection.
class UserDocumentPaths {
  UserDocumentPaths._();

  // ---- Collection ----
  static const collection = FirestoreCollections.users;

  // ---- Document paths ----
  static String doc(String userId) => '$collection/$userId';

  /// Generic helper when you just need `users/{id}/{sub}`.
  static String subcollection(String userId, String subCollection) =>
      '$collection/$userId/$subCollection';

  // ---- Named subcollections under each user ----
  static const favorites = 'favorites';
  static const fcmTokens = 'fcm_tokens';
  static const likes = 'likes';
  static const partyStatusDays = 'party_status_days';
  static const visits = 'visits';
  static const friends = 'friends';
  static const closeFriends = 'close_friends';

  static String favoritesCollection(String userId) =>
      '$collection/$userId/$favorites';

  static String fcmTokensCollection(String userId) =>
      '$collection/$userId/$fcmTokens';

  static String likesCollection(String userId) =>
      '$collection/$userId/$likes';

  static String partyStatusDaysCollection(String userId) =>
      '$collection/$userId/$partyStatusDays';

  static String visitsCollection(String userId) =>
      '$collection/$userId/$visits';

  static String friendsCollection(String userId) =>
      '$collection/$userId/$friends';

  static String closeFriendsCollection(String userId) =>
      '$collection/$userId/$closeFriends';

  // ---- Document field names (mirror `User.toJson`) ----
  static const email = 'email';
  static const userName = 'user_name';
  static const userNameLower = 'user_name_lc'; // search index / usernames
  static const birthDate = 'birth_date';
  static const gender = 'gender';

  static const firstName = 'first_name';
  static const middleName = 'middle_name';
  static const lastName = 'last_name';

  static const phoneNumber = 'phone_number';
  static const biography = 'biography';
  static const profilePictureUrl = 'profile_picture_url';

  static const homeCountry = 'home_country';
  static const homeTown = 'home_town';
  static const homeLocationLocked = 'home_location_locked';

  static const appVersion = 'app_version';
  static const isVerified = FirestoreFields.isVerified;

  static const level = 'level';
  static const xp = 'xp';

  static const preferredVenueTypes = 'preferred_venue_types';
  static const maxDistanceKm = 'max_distance_km';

  static const roles = 'roles';
  static const subscriptionType = 'subscription_type';
  static const platformType = 'platform_type';
  static const currentPartyStatus = 'current_party_status';

  static const createdAt = FirestoreFields.createdAt;
  static const updatedAt = FirestoreFields.updatedAt;
}
