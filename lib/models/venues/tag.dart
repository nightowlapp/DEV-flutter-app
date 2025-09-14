import 'package:cloud_firestore/cloud_firestore.dart';

/// Keep categories broad; specific values remain tags (docs) within these groups.
enum TagType {
  // Your core 3 first (kept for stable sorting priority)
  venue_type,     // club, bar... Everyone need 1
  entry_price,    // free, cheap, mid, expensive... Everyone need 1
  age_restriction,// 18_plus, 21_plus, 25_plus... Everyone need 1
  music,          // techno, house, hiphop, rnb... Max 2?
  vibe,           // chill, party, upscale, student, tourist... Max 2
  amenity,        // outdoor, rooftop, dancefloor, pool_table, arcade...
  smoking_policy, // indoor_smoking, outdoor_only, non_smoking... Everyone need 1
  dress_code,     // casual, smart_casual, strict...

  // Common additions (optional to use)
  crowd,          // mixed, lgbtq_friendly, international, locals...
  event,          // live_music, dj_set, karaoke, theme_night...
  service,        // bottle_service, coat_check, table_service...
  reservation,    // required, recommended, walk_in...
  accessibility,  // wheelchair_accessible, step_free, hearing_loop...
  payment,        // cash_only, card, mobilepay, apple_pay...
  hours,          // happy_hour, late_night, afterhours...
  line_policy,    // guestlist, queue_jump, members_only...
  sound,          // loud, moderate, acoustics_note, sound_system_brand...
  neighborhood,   // nørrebro, vesterbro, city_center...
  special,        // 2for1, student_discount, ladies_night...
  other,
}

extension TagTypeX on TagType {
  static TagType fromWire(String? s) {
    final v = (s ?? '').trim().toLowerCase();
    for (final t in TagType.values) {
      if (t.name == v) return t;
    }
    return TagType.other;
  }

  String get wire => name; // persisted to Firestore
}

class Tag {
  /// Firestore doc id (slug), equals lowercased/slugified name.
  final String id;

  final String name;  // Display label (can change freely)
  final TagType type; // Sorting/grouping
  final String emoji; // Optional ("" if none)

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Tag({
    required this.id,
    required this.name,
    required this.type,
    required this.emoji,
    this.createdAt,
    this.updatedAt,
  });

  // ---------- JSON / Firestore ----------
  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'type': type.wire,
    'emoji': emoji,
    // timestamps set in repository with serverTimestamp
  }..removeWhere((_, v) => v == null);

  factory Tag.fromJson(Map<String, dynamic> json, String id) => Tag(
    id: id,
    name: (json['name'] as String? ?? '').trim(),
    type: TagTypeX.fromWire(json['type'] as String?),
    emoji: (json['emoji'] as String? ?? '').trim(),
    createdAt: _asDate(json['created_at']),
    updatedAt: _asDate(json['updated_at']),
  );

  static Tag fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snap,
      SnapshotOptions? _,
      ) {
    final data = snap.data() ?? const <String, dynamic>{};
    return Tag.fromJson(data, snap.id);
  }

  static Map<String, Object?> toFirestore(Tag t, SetOptions? _) => t.toJson();
}

/// Utility to create a slug from a display name ("Smart Casual" -> "smart_casual")
String tagSlug(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
