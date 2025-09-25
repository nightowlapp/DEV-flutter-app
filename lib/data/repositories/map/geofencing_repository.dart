import 'package:cloud_firestore/cloud_firestore.dart';

class GeofencingRepository {
  GeofencingRepository(this.userId);
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final String userId;

  Future<void> setInside(String venueId) => db.collection('presence').doc(userId).set({
    'venue_id': venueId,
    'status': 'inside',
    'entered_at': FieldValue.serverTimestamp(),
    'updated_at': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  Future<void> setOutside(String? lastVenueId) => db.collection('presence').doc(userId).set({
    'venue_id': null, //TODO Make sure everything from database is snake_id
    'status': 'outside',
    'exited_at': FieldValue.serverTimestamp(),
    'updated_at': FieldValue.serverTimestamp(),
    if (lastVenueId != null) 'lastVenueId': lastVenueId,
  }, SetOptions(merge: true));

  Future<void> appendEvent(String venueId, String type) =>
      db.collection('venue_visits').doc(userId).collection(venueId).add({
        'type': type, // 'enter' | 'exit'
        'ts': FieldValue.serverTimestamp(),
      });
  //TODO Look into database structure of visits below.
  Future<void> enterVenue(String userId, String venueId, FirebaseFirestore db) {
    final presenceRef = db.collection('presence').doc(userId);
    final sessionsCol = db.collection('visits').doc(userId).collection('sessions');

    return db.runTransaction((tx) async {
      // close any existing open session
      final open = await sessionsCol.where('exitedAt', isNull: true).limit(1).get();
      if (open.docs.isNotEmpty) {
        tx.update(open.docs.first.reference, {'exitedAt': FieldValue.serverTimestamp()});
      }

      // create new session
      final dayKey = DateTime.now().toUtc().toIso8601String().substring(0, 10).replaceAll('-', '');
      final sessionRef = sessionsCol.doc(); // or deterministic id
      tx.set(sessionRef, {
        'venue_id': venueId,
        'entered_at': FieldValue.serverTimestamp(),
        'exited_at': null,
        'dayKey': dayKey,
        'source': 'geofence',
      });

      // update presence
      tx.set(presenceRef, {
        'current_venue_id': venueId,
        'session_id': sessionRef.id,
        'status': 'inside',
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> exitVenue(String userId, FirebaseFirestore db) {
    final presenceRef = db.collection('presence').doc(userId);
    final sessionsCol = db.collection('visits').doc(userId).collection('sessions');

    return db.runTransaction((tx) async {
      final p = await tx.get(presenceRef);
      final sessionId = p.data()?['session_id'] as String?;
      if (sessionId != null) {
        tx.update(sessionsCol.doc(sessionId), {'exited_at': FieldValue.serverTimestamp()});
      } else {
        // fallback: close the last open session if any
        final open = await sessionsCol.where('exited_at', isNull: true).limit(1).get();
        if (open.docs.isNotEmpty) {
          tx.update(open.docs.first.reference, {'exited_at': FieldValue.serverTimestamp()});
        }
      }
      tx.set(presenceRef, {
        'current_venue_id': null,
        'session_id': null,
        'status': 'outside',
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

}
