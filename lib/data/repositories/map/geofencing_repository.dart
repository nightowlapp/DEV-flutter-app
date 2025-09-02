import 'package:cloud_firestore/cloud_firestore.dart';

class GeofencingRepository {
  GeofencingRepository(this.userId);
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final String userId;

  Future<void> setInside(String venueId) => db.collection('presence').doc(userId).set({
    'venueId': venueId,
    'status': 'inside',
    'enteredAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  Future<void> setOutside(String? lastVenueId) => db.collection('presence').doc(userId).set({
    'venueId': null, //TODO Make sure everything from database is snake_id
    'status': 'outside',
    'exitedAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
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
        'venueId': venueId,
        'enteredAt': FieldValue.serverTimestamp(),
        'exitedAt': null,
        'dayKey': dayKey,
        'source': 'geofence',
      });

      // update presence
      tx.set(presenceRef, {
        'currentVenueId': venueId,
        'sessionId': sessionRef.id,
        'status': 'inside',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> exitVenue(String userId, FirebaseFirestore db) {
    final presenceRef = db.collection('presence').doc(userId);
    final sessionsCol = db.collection('visits').doc(userId).collection('sessions');

    return db.runTransaction((tx) async {
      final p = await tx.get(presenceRef);
      final sessionId = p.data()?['sessionId'] as String?;
      if (sessionId != null) {
        tx.update(sessionsCol.doc(sessionId), {'exitedAt': FieldValue.serverTimestamp()});
      } else {
        // fallback: close the last open session if any
        final open = await sessionsCol.where('exitedAt', isNull: true).limit(1).get();
        if (open.docs.isNotEmpty) {
          tx.update(open.docs.first.reference, {'exitedAt': FieldValue.serverTimestamp()});
        }
      }
      tx.set(presenceRef, {
        'currentVenueId': null,
        'sessionId': null,
        'status': 'outside',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

}
