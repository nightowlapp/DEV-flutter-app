// lib/models/visit_session.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class VisitSession {
  final String id; // session doc id
  final String venueId;
  final DateTime? enteredAt; // server Timestamp
  final DateTime? exitedAt; // server Timestamp or null
  final String source; // 'geofence' | 'manual' etc.

  const VisitSession({
    required this.id,
    required this.venueId,
    required this.enteredAt,
    required this.exitedAt,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'venue_id': venueId,
        'entered_at': FieldValue.serverTimestamp(),
        'exited_at': null,
        'source': source,
        // NOTE: flags below are for CF idempotency; client shouldn’t set them.
        // '_inc_applied': false,
        // '_dec_applied': false,
      };

  static VisitSession fromSnap(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return VisitSession(
      id: d.id,
      venueId: (m['venue_id'] as String?) ?? '',
      enteredAt: (m['entered_at'] as Timestamp?)?.toDate(),
      exitedAt: (m['exited_at'] as Timestamp?)?.toDate(),
      source: (m['source'] as String?) ?? 'geofence',
    );
  }
}
