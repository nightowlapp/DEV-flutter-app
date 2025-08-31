// class Event { //TODO NOT used right now.
//   const Event( {
//     required this.id,
//     required this.venueid,
//     required this.title,
//     this.location,
//     this.description,
//     required this.start,
//     required this.end,
//   });
//
//   final String id;
//   final String venueid;
//   // Core
//   final String title;
//   final String description;
//   final DateTime startUtc;
//   final DateTime endUtc;
//
//   // Denorm for fast queries (computed with venue.timeZoneId):
//   final int startLocalYmd;      // e.g., 20250820
//   final int endLocalYmd;        // for multi-day events
//   final int startLocalMinutes;  // 0..1439
//   final String? timeZoneId;     // IANA, mirror from venue at creation
//
//   // Door/price toggles (event-specific)
//   final int? ageRestriction;        // overrides venue/day
//   final double? entryPrice;         // overrides defaultEntryPrice
//   final DressCodeType? dressCode;   // overrides venue
//   final String status;        // "scheduled" | "canceled" | "postponed"
//   final String? ticketUrl;
//   final String? imageUrl;
//   final List<String> tags;    // genre, theme
//   final String venueNameSnap; // small denorm for stable display
//   final String citySnap;      // for filtering without extra read
//   final String geohash;       // for map/bounds queries
//
//
// }
