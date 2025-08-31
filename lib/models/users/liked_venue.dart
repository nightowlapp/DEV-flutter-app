// models/users/liked_venue.dart
import 'package:flutter/foundation.dart';

@immutable
class LikedVenue {
  /// The document id == venueId
  final String id;
  final DateTime createdAt;

  LikedVenue({
    required this.id,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'created_at': createdAt.toIso8601String(),
  };

  static LikedVenue fromJson(Map<String, dynamic> json, String id) {
    final v = json['created_at'];
    DateTime asDate(dynamic x) {
      if (x == null) return DateTime.now();
      if (x is DateTime) return x;
      if (x.runtimeType.toString() == 'Timestamp') return (x as dynamic).toDate() as DateTime;
      if (x is String) return DateTime.tryParse(x) ?? DateTime.now();
      if (x is int) return DateTime.fromMillisecondsSinceEpoch(x);
      return DateTime.now();
    }

    return LikedVenue(id: id, createdAt: asDate(v));
  }
}
