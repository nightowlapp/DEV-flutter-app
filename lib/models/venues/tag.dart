// models/venues/tag.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/utility/json_utility.dart';

class Tag {
  final String id;        // doc id (e.g., "dance")
  final String name;      // display name (e.g., "Dance")
  final String emoji;     // e.g., "💃"
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Tag({
    required this.id,
    required this.name,
    required this.emoji,
    this.createdAt,
    this.updatedAt,
  });

  // ----- JSON helpers -----
  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'name_lc': name.toLowerCase().trim(), // for case-insensitive search
    'emoji': emoji,
    // do NOT write created/updated here; repo sets server timestamps
  };

  factory Tag.fromJson(Map<String, dynamic> json, String id) => Tag(
    id: id,
    name: JsonUtility.nullIfEmpty(json['name'] as String?) ?? '',
    emoji: JsonUtility.nullIfEmpty(json['emoji'] as String?) ?? '',
    createdAt: _asDate(json['created_at']),
    updatedAt: _asDate(json['updated_at']),
  );

  // ----- Firestore converters (correct signatures) -----
  static Tag fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snap,
      SnapshotOptions? _,
      ) {
    final data = snap.data() ?? const <String, dynamic>{};
    return Tag.fromJson(data, snap.id);
  }

  static Map<String, Object?> toFirestore(
      Tag tag,
      SetOptions? _,
      ) {
    final json = tag.toJson();
    json.removeWhere((_, v) => v == null);
    return json;
  }


}
