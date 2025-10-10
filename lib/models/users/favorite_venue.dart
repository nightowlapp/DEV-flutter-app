// models/users/favorite_venue.dart
import 'package:flutter/foundation.dart';

@immutable
class FavoriteVenue {
  /// The document id == venueId
  final String id;
  final DateTime createdAt;

  FavoriteVenue({
    required this.id,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        // doc id is the venue id, we only store meta
        'created_at': createdAt.toIso8601String(),
      };

  static FavoriteVenue fromJson(Map<String, dynamic> json, String id) {
    final v = json['created_at'];
    DateTime asDate(dynamic x) {
      if (x == null) return DateTime.now();
      if (x is DateTime) return x;
      if (x.runtimeType.toString() == 'Timestamp')
        return (x as dynamic).toDate() as DateTime;
      if (x is String) return DateTime.tryParse(x) ?? DateTime.now();
      if (x is int) return DateTime.fromMillisecondsSinceEpoch(x);
      return DateTime.now();
    }

    return FavoriteVenue(id: id, createdAt: asDate(v));
  }
}
