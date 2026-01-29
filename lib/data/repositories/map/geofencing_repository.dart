import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightowlcode/data/firestore_paths/firestore_paths.dart';

class GeofencingRepository {
  GeofencingRepository(this.userId, {FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _sessionsCol =>
      _db.collection(VisitDocumentPaths.collectionForUser(userId));

  /// Ensure there is exactly one *open* session per [venueId].
  /// - If an open session for the same venue already exists → do nothing, return its id.
  /// - If an open session exists for a different venue → close it, open a new one for [venueId].
  /// - If no open session exists → open a new one for [venueId].
  Future<String> enterVenue(
    String venueId, {
    String source = 'geofence',
  }) async {
    // Fetch any open sessions (normally 0 or 1, but we tolerate >1 and fix it)
    final openSnap = await _sessionsCol
        .where(VisitDocumentPaths.exitedAt, isNull: true)
        .limit(10)
        .get();
    final openDocs = openSnap.docs;

    // 1) If there is already an open session for THIS venue → no-op
    for (final d in openDocs) {
      final data = d.data();
      if ((data[VisitDocumentPaths.venueId] as String?) == venueId) {
        return d.id; // already open for this venue
      }
    }

    // 2) Otherwise: close any open sessions (different venues) + create a new one atomically
    final batch = _db.batch();

    for (final d in openDocs) {
      batch.update(d.reference, {
        VisitDocumentPaths.exitedAt: FieldValue.serverTimestamp(),
      });
    }

    final doc = _sessionsCol.doc(); // new session id
    batch.set(doc, {
      VisitDocumentPaths.venueId: venueId,
      VisitDocumentPaths.enteredAt: FieldValue.serverTimestamp(),
      VisitDocumentPaths.exitedAt: null,
      VisitDocumentPaths.source: source,
    });

    await batch.commit();
    return doc.id;
  }

  /// Mark the latest open session as exited.
  /// If [venueId] is provided, only close an open session for that venue.
  /// If multiple open sessions exist (shouldn't, but may), close them all defensively.
  Future<void> exitVenue({String? venueId}) async {
    Query<Map<String, dynamic>> q =
        _sessionsCol.where(VisitDocumentPaths.exitedAt, isNull: true);
    if (venueId != null) {
      q = q.where(VisitDocumentPaths.venueId, isEqualTo: venueId);
    }

    final snap = await q.limit(10).get();
    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {
        VisitDocumentPaths.exitedAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
