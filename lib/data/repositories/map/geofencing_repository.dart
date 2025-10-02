// lib/data/repositories/geofencing_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightowlcode/data/firestore_paths.dart';

class GeofencingRepository {
  GeofencingRepository(this.userId, {FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _sessionsCol =>
      _db.collection(DocumentPaths.users).doc(userId).collection(DocumentPaths.visits);
  //Todo find all .collection(' and rename to consts in docpaths.

  /// Create a new *open* session for venue
  Future<String> enterVenue(String venueId, {String source = 'geofence'}) async {
    // Close any open session defensively (rare, but keeps data clean)
    final open = await _sessionsCol.where('exited_at', isNull: true).limit(1).get();
    if (open.docs.isNotEmpty) {
      await open.docs.first.reference.update({'exited_at': FieldValue.serverTimestamp()});
    }

    final doc = _sessionsCol.doc(); // auto id
    await doc.set({
      'venue_id': venueId,
      'entered_at': FieldValue.serverTimestamp(),
      'exited_at': null,
      'source': source,
    });
    return doc.id;
  }

  /// Mark the latest open session as exited (optionally restrict to venue)
  Future<void> exitVenue({String? venueId}) async {
    Query<Map<String, dynamic>> q = _sessionsCol.where('exited_at', isNull: true).orderBy('entered_at', descending: true);
    if (venueId != null) q = q.where('venue_id', isEqualTo: venueId);

    final snap = await q.limit(1).get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({'exited_at': FieldValue.serverTimestamp()});
    }
  }
}
