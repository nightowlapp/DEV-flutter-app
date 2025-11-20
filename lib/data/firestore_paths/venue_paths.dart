import 'firestore_collections .dart';

/// Firestore paths & fields for the top-level `venues` collection.
class VenueDocumentPaths {
  VenueDocumentPaths._();

  static const collection = FirestoreCollections.venues;

  static String doc(String venueId) => '$collection/$venueId';

  static String subcollection(String venueId, String subCollection) =>
      '$collection/$venueId/$subCollection';

  // ---- Subcollections under each venue ----
  // Based on your `entries` constant.
  static const entries = 'entries';

  static String entriesCollection(String venueId) =>
      '$collection/$venueId/$entries';

  // ---- Document fields (mirror `Venue.toJson`) ----
  static const companyNumber = 'company_number';
  static const name = 'name';
  static const displayName = 'display_name';
  static const logoUrl = 'logo_url';
  static const type = 'type';

  // Location
  static const entry = 'entry';
  static const geohash = 'geohash';
  static const countryCode = 'country_code';
  static const city = 'city';
  static const corners = 'corners';

  // Metrics
  static const rating = 'rating';
  static const ratingCount = 'rating_count';
  static const likeCount = 'like_count';
  static const favoriteCount = 'favorite_count';
  static const visitCount = 'visit_count';

  // Opening hours
  static const openingHours = 'opening_hours';

  // Media
  static const coverImageUrl = 'cover_image_url';
  static const barCardUrl = 'bar_card_url';
  static const moodImageUrls = 'mood_image_urls';
  static const defaultOfferUrl = 'default_offer_url';
  static const dailyOfferUrls = 'daily_offer_urls';

  // Auditing
  static const createdAt = FirestoreFields.createdAt;
  static const updatedAt = FirestoreFields.updatedAt;

  static const defaultEntryPrice = 'default_entry_price';

  // Links & contact
  static const links = 'links';
  static const email = 'email';
  static const phone = 'phone';

  // Subscription / capacity
  static const subscriptionType = 'subscription_type';
  static const defaultAgeRestriction = 'default_age_restriction';
  static const capacity = 'capacity';

  // Visual identity
  static const defaultDressCode = 'default_dress_code';
  static const isVerified = FirestoreFields.isVerified;
  static const primaryColorHex = 'primary_color_hex';
  static const secondaryColorHex = 'secondary_color_hex';
  static const fontFamily = 'font_family';

  // Tags & timezone
  static const tagIds = 'tag_ids';
  static const timeZoneId = 'time_zone_id';
  static const description = 'description';
}
