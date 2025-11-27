// lib/models/users/live_location.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/firestore_paths/firestore_collections .dart';

class LiveLocation {
  final String uid;
  final double lat;
  final double lng;
  final double? accuracy; // meters
  final double? heading; // deg
  final double? speed; // m/s
  final DateTime timestamp; // from Firestore 'timestamp' / 'updated_at'

  LiveLocation({
    required this.uid,
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.accuracy,
    this.heading,
    this.speed,
  });

  /// New-style doc from LiveLocationPublisher:
  /// { lat, lng, accuracy?, heading?, speed?, timestamp }
  static LiveLocation fromDoc(String uid, Map<String, dynamic> m) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final lat = _toDouble(m['lat']);
    final lng = _toDouble(m['lng']);
    if (lat == null || lng == null) {
      throw StateError('LiveLocation.fromDoc missing lat/lng for $uid');
    }

    final ts = m['timestamp'] as Timestamp?;
    return LiveLocation(
      uid: uid,
      lat: lat,
      lng: lng,
      accuracy: _toDouble(m['accuracy']),
      heading: _toDouble(m['heading']),
      speed: _toDouble(m['speed']),
      timestamp: ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Old-style doc (what you showed in the screenshot):
  /// { last_known_lat, last_known_lon, updated_at }
  factory LiveLocation.fromLocationDoc(
      String uid,
      Map<String, dynamic> data,
      ) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final lat = _toDouble(data[LocationDocumentPaths.lastKnownLat]);
    final lng = _toDouble(data[LocationDocumentPaths.lastKnownLon]);
    if (lat == null || lng == null) {
      throw StateError('LiveLocation.fromLocationDoc missing lat/lng for $uid');
    }

    final ts = data[FirestoreFields.updatedAt] as Timestamp?;
    return LiveLocation(
      uid: uid,
      lat: lat,
      lng: lng,
      timestamp: ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Helper that tries new schema first, then old one.
  static LiveLocation fromAny(String uid, Map<String, dynamic> m) {
    // New schema has lat/lng, old schema has last_known_lat/lon
    if (m.containsKey('lat') || m.containsKey('lng')) {
      return fromDoc(uid, m);
    }
    return LiveLocation.fromLocationDoc(uid, m);
  }

  /// Convenience: is this location still fresh?
  bool get isFresh24h =>
      DateTime.now().difference(timestamp) <= const Duration(hours: 24);
}
