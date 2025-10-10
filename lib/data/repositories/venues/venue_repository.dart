// lib/data/repositories/venues/venue_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'venue_collections.dart';
import '../../../models/venues/venue.dart';

class VenueRepository {
  VenueRepository({FirebaseFirestore? db}) : _c = VenueCollections(db: db);
  final VenueCollections _c;

  Stream<List<Venue>> watchAll(
      {int? limit, String orderBy = 'created_at', bool desc = true}) {
    Query<Venue> q = _c.venues;
    if (orderBy.isNotEmpty) q = q.orderBy(orderBy, descending: desc);
    if (limit != null) q = q.limit(limit);
    return q.snapshots().map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<List<Venue>> getAll(
      {int? limit, String orderBy = 'created_at', bool desc = true}) async {
    Query<Venue> q = _c.venues;
    if (orderBy.isNotEmpty) q = q.orderBy(orderBy, descending: desc);
    if (limit != null) q = q.limit(limit);
    final snap = await q.get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Stream<Venue?> watchById(String id) =>
      _c.venues.doc(id).snapshots().map((s) => s.data());
  Future<Venue?> getById(String id) async =>
      (await _c.venues.doc(id).get()).data();

  Future<void> update(Venue v) async {
    final ref = _c.venues.doc(v.id);
    await ref.set(v, SetOptions(merge: true));
    await ref.update({'updated_at': FieldValue.serverTimestamp()});
  }

  Future<void> create(Venue v) async {
    final ref = _c.venues.doc(v.id);
    await ref.firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        tx.update(ref, {'updated_at': FieldValue.serverTimestamp()});
      } else {
        tx.set(ref, v);
        tx.update(ref, {
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> delete(String id) => _c.venues.doc(id).delete();
}
