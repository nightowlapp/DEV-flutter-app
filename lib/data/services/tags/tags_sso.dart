// lib/data/tags/tags_sso.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/tags_local_store.dart';
import '../../../models/venues/tag.dart';
import '../../other_providers.dart';

final tagsSsoProvider = AsyncNotifierProvider<TagsSso, Map<String, Tag>>(TagsSso.new);

class TagsSso extends AsyncNotifier<Map<String, Tag>> {
  StreamSubscription? _sub;
  final _store = TagsLocalStore();

  @override
  Future<Map<String, Tag>> build() async {
    // 1) serve cached immediately
    final cachedList = await _store.readAll();
    final cached = { for (final t in cachedList) t.id: t };
    state = AsyncData(cached);

    // 2) subscribe to Firestore
    final db = ref.read(firestoreProvider);
    final col = db.collection('tags')
        .withConverter<Tag>(fromFirestore: Tag.fromFirestore, toFirestore: Tag.toFirestore);

    _sub?.cancel();
    _sub = col.snapshots().listen((snap) async {
      final fresh = <String, Tag>{};
      for (final d in snap.docs) {
        final t = d.data();
        fresh[t.id] = t;
      }
      await _store.writeAll(fresh.values.toList());
      state = AsyncData(fresh);
    }, onError: (e, st) {
      state = AsyncError(e, st);
    });

    // Ensure cleanup
    ref.onDispose(() async {
      await _sub?.cancel();
      _sub = null;
    });

    return cached;
  }
}
