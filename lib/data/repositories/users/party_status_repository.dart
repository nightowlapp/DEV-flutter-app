import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:geolocator/geolocator.dart';
import 'package:nightowlcode/data/firestore_paths/firestore_paths.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

import '../../../models/users/party_status.dart';

class PartyStatusRepository {
  PartyStatusRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final fb.FirebaseAuth _auth;

  String _uid() {
    final u = _auth.currentUser;
    if (u == null) {
      throw StateError('Not authenticated');
    }
    return u.uid;
  }

  /// Day id like "2025-09-03" in the user's *local* time (midnight boundary for DB grouping).
  String dayId(DateTime localNow) {
    final d = DateTime(localNow.year, localNow.month, localNow.day);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  CollectionReference<Map<String, dynamic>> _dayEntriesCol(
      String uid,
      String dayId,
      ) {
    return _db
        .collection(UserDocumentPaths.collection)
        .doc(uid)
        .collection(UserDocumentPaths.partyStatusDays)
        .doc(dayId)
        .collection('entries'); // day sub-subcollection
  }

  /// Record a change (history) and mirror the latest into the user root doc.
  Future<void> recordStatus({
    required PartyStatusTypes status,
    PartyStatusChange change = PartyStatusChange.manual,
    Position? position,
    DateTime? now,
  }) async {
    final uid = _uid();
    final at = now ?? DateTime.now();
    final day = dayId(at);
    final (geo, acc) = PartyStatusEntry.fromPosition(position);

    final entry = PartyStatusEntry(
      id: '', // auto-id on create
      partyStatus: status,
      partyStatusChange: change,
      createdAt: at,
      location: geo,
      accuracy: acc,
    );

    final batch = _db.batch();

    // Create per-day entry
    final entryRef = _dayEntriesCol(uid, day).doc(); // autoId
    batch.set(entryRef, entry.toJson());

    // Update user mirror (fast read for "currentPartyStatus")
    final userRef = _db.doc(UserDocumentPaths.doc(uid));
    batch.update(userRef, {
      UserDocumentPaths.currentPartyStatus: status.name,
      UserDocumentPaths.updatedAt: FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Read the mirrored latest status + timestamp from user root.
  Future<CurrentPartyStatus> loadCurrent() async {
    final uid = _uid();
    final doc = await _db.doc(UserDocumentPaths.doc(uid)).get();
    final raw =
    doc.data()?[UserDocumentPaths.currentPartyStatus] as String?;

    final status = (raw == null || raw.isEmpty)
        ? null
        : PartyStatusTypes.values.firstWhere(
          (e) => e.name == raw,
      orElse: () => PartyStatusTypes.still_planning,
    );

    return CurrentPartyStatus(status!);
  }

  /// Stream today’s history if you need it.
  Stream<List<PartyStatusEntry>> watchTodayEntries() {
    final uid = _uid();
    final day = dayId(DateTime.now().toLocal());
    return _dayEntriesCol(uid, day)
        .orderBy(FirestoreFields.createdAt, descending: true)
        .snapshots()
        .map((q) => q.docs.map(PartyStatusEntry.fromSnapshot).toList());
  }
}
