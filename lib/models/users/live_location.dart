// lib/models/live_location.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveLocation {
  final String uid;
  final double lat;
  final double lng;
  final double? accuracy; // meters
  final double? heading; // deg
  final double? speed; // m/s
  final DateTime timestamp; // from Firestore 'timestamp'

  LiveLocation({
    required this.uid,
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.accuracy,
    this.heading,
    this.speed,
  });

  /// Parse from Firestore
  static LiveLocation fromDoc(String uid, Map<String, dynamic> m) {
    final ts = m['timestamp'] as Timestamp?;
    return LiveLocation(
      uid: uid,
      lat: (m['lat'] as num).toDouble(),
      lng: (m['lng'] as num).toDouble(),
      accuracy: (m['accuracy'] as num?)?.toDouble(),
      heading: (m['heading'] as num?)?.toDouble(),
      speed: (m['speed'] as num?)?.toDouble(),
      timestamp: ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory LiveLocation.fromLocationDoc(
    String uid,
    Map<String, dynamic> data,
  ) {
    final lat = (data['last_known_lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (data['last_known_lon'] as num?)?.toDouble() ?? 0.0;
    final ts =
      (data['updated_at'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return LiveLocation(
      uid: uid,
      lat: lat,
      lng: lng,
      timestamp: ts,
    );
  }
}
