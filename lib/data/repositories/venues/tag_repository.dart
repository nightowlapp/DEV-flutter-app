import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/venues/tag.dart';

class TagRepository {
  final FirebaseFirestore _db;
  TagRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Tag> get _tags =>
      _db.collection('tags').withConverter<Tag>(
          fromFirestore: Tag.fromFirestore, toFirestore: Tag.toFirestore);

  /// Watch a single tag
  Stream<Tag?> watchById(String id) =>
      _tags.doc(id).snapshots().map((s) => s.data());

  /// Watch many by IDs (chunked whereIn). Emits merged, ordered by the incoming ids list.
  Stream<List<Tag>> watchByIds(List<String> ids) {
    // sanitize: trim, drop empty/null, drop ids with '/', de-dup while preserving input order
    final seen = <String>{};
    final clean = <String>[];
    for (final raw in ids) {
      final id = (raw).trim();
      if (id.isEmpty || id.contains('/')) continue;
      if (seen.add(id)) clean.add(id);
    }
    if (clean.isEmpty) return Stream.value(const <Tag>[]);

    final controller = StreamController<List<Tag>>();
    final subs = <StreamSubscription>[];
    final map = <String, Tag?>{for (final id in clean) id: null};

    void emitIfReady() {
      // We emit on *every* change; nulls (not found) are skipped
      final out = <Tag>[];
      for (final id in clean) {
        final t = map[id];
        if (t != null) out.add(t);
      }
      controller.add(out);
    }

    for (final id in clean) {
      final sub = _tags.doc(id).snapshots().listen(
        (snap) {
          map[id] = snap.data(); // can be null if doc doesn't exist
          emitIfReady();
        },
        onError: controller.addError,
      );
      subs.add(sub);
    }

    controller.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };

    return controller.stream;
  }

  /// Optional: one-shot fetch (kept for admin/batch use)
  Future<List<Tag>> getByIds(List<String> ids) async {
    final clean = ids
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !e.contains('/'))
        .toList();
    if (clean.isEmpty) return <Tag>[];

    // still fine to do whereIn here with chunking for a one-shot
    const maxChunk = 10;
    final futures = <Future<QuerySnapshot<Tag>>>[];
    for (var i = 0; i < clean.length; i += maxChunk) {
      final end = (i + maxChunk > clean.length) ? clean.length : i + maxChunk;
      final chunk = clean.sublist(i, end);
      futures.add(_tags.where(FieldPath.documentId, whereIn: chunk).get());
    }
    final snaps = await Future.wait(futures);
    final map = <String, Tag>{};
    for (final s in snaps) {
      for (final d in s.docs) {
        map[d.id] = d.data();
      }
    }
    return clean.where(map.containsKey).map((id) => map[id]!).toList();
  }

  // Admin upsert (keep it simple). Ensure you pass the desired doc id (slug).
  Future<void> upsert(Tag tag) async {
    final ref = _tags.doc(tag.id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        tx.set(ref, tag, SetOptions(merge: true));
        tx.update(ref, {'updated_at': FieldValue.serverTimestamp()});
      } else {
        tx.set(ref, tag);
        tx.update(ref, {
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}

/// Utility to create a slug from a display name ("Smart Casual" -> "smart_casual")
String tagSlug(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
