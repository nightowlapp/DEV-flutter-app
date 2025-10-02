// lib/models/live_location.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveLocation {
  final String uid;
  final double lat;
  final double lng;
  final double? accuracy; // meters
  final double? heading;  // deg
  final double? speed;    // m/s
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

  /// Firestore payload (snake_case + 'timestamp' as Firestore Timestamp)
  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'accuracy': accuracy,
    'heading': heading,
    'speed': speed,
    'timestamp': FieldValue.serverTimestamp(), // ✅ Timestamp
  };

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
}
