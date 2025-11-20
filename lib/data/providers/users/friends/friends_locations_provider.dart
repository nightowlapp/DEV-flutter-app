// lib/data/providers/friends_locations_provider.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/firestore_paths/firestore_paths.dart';

import '../../../../models/users/live_location.dart';

final friendsIdsProvider = Provider<List<String>>((ref) => <String>[]);

final friendsLocationsProvider =
    StreamProvider<Map<String, LiveLocation>>((ref) {
  final ids = ref.watch(friendsIdsProvider);
  final db = FirebaseFirestore.instance;
  if (ids.isEmpty) return const Stream.empty();

  Iterable<List<String>> chunks(int size) sync* {
    for (var i = 0; i < ids.length; i += size) {
      yield ids.sublist(i, (i + size > ids.length) ? ids.length : i + size);
    }
  }

  final latest = <String, LiveLocation>{};
  final controller = StreamController<Map<String, LiveLocation>>.broadcast();
  final subs = <StreamSubscription>[];

  void emit() => controller.add(Map<String, LiveLocation>.from(latest));

  for (final chunk in chunks(10)) {
    final sub = db
        .collection(FirestoreCollections.locations)
        .where(FieldPath.documentId, whereIn: chunk)
        .snapshots()
        .listen((snap) {
      for (final ch in snap.docChanges) {
        final id = ch.doc.id;
        if (ch.type == DocumentChangeType.removed) {
          latest.remove(id);
        } else {
          latest[id] = LiveLocation.fromDoc(id, ch.doc.data()!);
        }
      }
      if (snap.docChanges.isEmpty) {
        latest
          ..removeWhere((k, _) => chunk.contains(k))
          ..addEntries(snap.docs.map(
              (d) => MapEntry(d.id, LiveLocation.fromDoc(d.id, d.data()))));
      }
      emit();
    });
    subs.add(sub);
  }

  controller.onCancel = () {
    for (final s in subs) {
      s.cancel();
    }
  };

  return controller.stream;
});
