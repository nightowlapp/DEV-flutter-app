// lib/data/repositories/venues/tag_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/venues/tag.dart';
import '../../firestore_paths.dart';

class TagRepository {
  final FirebaseFirestore _db;
  TagRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Tag> get _tags => _db
      .collection(DocumentPaths.tags)
      .withConverter<Tag>(fromFirestore: Tag.fromFirestore, toFirestore: Tag.toFirestore);

  Future<Tag?> getById(String id) async => (await _tags.doc(id).get()).data();

  Stream<Tag?> watchById(String id) => _tags.doc(id).snapshots().map((s) => s.data());

  Future<void> create(Tag tag) async {
    final ref = _tags.doc(tag.id);
    await ref.firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
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

  Future<void> update(Tag tag) async {
    final ref = _tags.doc(tag.id);
    await ref.set(tag, SetOptions(merge: true));
    await ref.update({'updated_at': FieldValue.serverTimestamp()});
  }

  Future<void> delete(String id) => _tags.doc(id).delete();

  // Efficient batch fetch by doc IDs (chunked)
  Future<List<Tag>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    const maxChunk = 10; // safe chunk size for whereIn
    final futures = <Future<QuerySnapshot<Tag>>>[];
    for (var i = 0; i < ids.length; i += maxChunk) {
      final chunk = ids.sublist(i, (i + maxChunk).clamp(0, ids.length));
      futures.add(_tags
          .where(FieldPath.documentId, whereIn: chunk)
          .get());
    }
    final snaps = await Future.wait(futures);
    return snaps.expand((s) => s.docs.map((d) => d.data())).toList();
  }

  // Case-insensitive search using name_lc
  Stream<List<Tag>> searchByName(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const Stream<List<Tag>>.empty();
    return _tags
        .orderBy('name_lc')
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }
}
