import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:nightowlcode/data/repositories/venues/venue_converters.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/data/other_providers.dart';            // firestoreProvider
import 'package:nightowlcode/data/firestore_paths.dart';      // DocumentPaths.venues

// ---------- Local persistent store (Hive, JSON per venue) ----------

class VenuesLocalStore {
  static const _boxName = 'venues_box';
  static const _kLastSync = '__lastSyncIso';

  VenuesLocalStore._(this._box);
  final Box _box;

  static Future<VenuesLocalStore> open() async {
    final box = await Hive.openBox(_boxName);
    return VenuesLocalStore._(box);
  }

  Future<bool> get isEmpty async {
    // ignore special keys
    return _box.keys.where((k) => k is String && k != _kLastSync).isEmpty;
    // NOTE: Box.isEmpty counts lastSync as well; we want only venue entries.
  }

  Future<DateTime?> getLastSync() async {
    final iso = _box.get(_kLastSync) as String?;
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  Future<void> setLastSync(DateTime value) async {
    await _box.put(_kLastSync, value.toUtc().toIso8601String());
  }

  // Upsert a single venue
  Future<void> upsert(Venue v) async {
    // Use your Firestore converter, but make it JSON-safe
    final mapFs = VenueFirestore.toMap(v);
    mapFs['id'] ??= v.id;
    final safe = _jsonSafe(mapFs) as Map<String, dynamic>;
    await _box.put(v.id, jsonEncode(safe));
  }

  // Upsert many venues at once
  Future<void> upsertMany(Iterable<Venue> venues) async {
    final entries = <String, String>{};
    for (final v in venues) {
      final mapFs = VenueFirestore.toMap(v);
      mapFs['id'] ??= v.id;
      final safe = _jsonSafe(mapFs) as Map<String, dynamic>;
      entries[v.id] = jsonEncode(safe);
    }
    await _box.putAll(entries);
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  Future<List<Venue>> getAll() async {
    final result = <Venue>[];
    for (final key in _box.keys) {
      if (key == _kLastSync) continue;
      final raw = _box.get(key);
      if (raw is String) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final id = (map['id'] as String?) ?? key; // fallback to box key
          result.add(Venue.fromJson(map, id));
        } catch (_) {
          // best-effort; skip broken entry
        }
      }
    }
    return result;
  }
}

dynamic _jsonSafe(dynamic v) {
  if (v == null) return null;
  if (v is GeoPoint)      return {'lat': v.latitude, 'lng': v.longitude};
  if (v is Timestamp)     return v.millisecondsSinceEpoch; // or v.toDate().toIso8601String()
  if (v is DateTime)      return v.toIso8601String();
  if (v is DocumentReference) return v.path;
  if (v is Iterable)      return v.map(_jsonSafe).toList();
  if (v is Map)           return v.map((k, val) => MapEntry(k.toString(), _jsonSafe(val)));
  return v; // num/bool/String
}

// ---------- Providers ----------

final venuesLocalStoreProvider = FutureProvider<VenuesLocalStore>((ref) async {
  return VenuesLocalStore.open();
});



class VenuesSso extends AsyncNotifier<List<Venue>> {
  StreamSubscription<QuerySnapshot<Venue>>? _sub;
  KeepAliveLink? _keepAlive;

  @override
  Future<List<Venue>> build() async {
    _keepAlive ??= ref.keepAlive();
    final store = await ref.watch(venuesLocalStoreProvider.future);
    final db = ref.watch(firestoreProvider);

    // 1) Seed from local cache for instant UI
    final local = await store.getAll();
    state = AsyncData(local);

    // 2) If cache empty: fetch ALL once and cache
    if (await store.isEmpty) {
      final all = await _fetchAllOnce(db);
      await store.upsertMany(all);
      await store.setLastSync(DateTime.now());
      state = AsyncData(all);
    }

    // 3) Start live incremental sync
    await _startLiveSync(db, store);

    ref.onDispose(() async {
      await _sub?.cancel();
    });

    return state.value ?? <Venue>[];
  }

  Future<List<Venue>> _fetchAllOnce(FirebaseFirestore db) async {
    final col = db.collection(DocumentPaths.venues).withConverter<Venue>(
      fromFirestore: (snap, _) => VenueFirestore.fromSnapshot(snap),
      toFirestore: (v, _) => VenueFirestore.toMap(v),
    );

    final snap = await col.get(const GetOptions(source: Source.server));
    return snap.docs.map((d) => d.data()).toList(growable: false);
  }

  Future<void> _startLiveSync(
      FirebaseFirestore db, VenuesLocalStore store) async {
    final col = db.collection(DocumentPaths.venues).withConverter<Venue>(
      fromFirestore: (snap, _) => VenueFirestore.fromSnapshot(snap),
      toFirestore: (v, _) => VenueFirestore.toMap(v),
    );

    // Prefer delta updates if backend has an `updatedAt` field (Timestamp)
    Stream<QuerySnapshot<Venue>> stream;
    final lastSync = await store.getLastSync();

    try {
      if (lastSync != null) {
        stream = col
            .where('updated_at', isGreaterThan: Timestamp.fromDate(lastSync))
            .snapshots();
      } else {
        // Fallback: full snapshot (first emission will contain all docs)
        stream = col.snapshots();
      }
    } catch (_) {
      // If the field doesn't exist, fall back to full snapshots
      stream = col.snapshots();
    }

    // Cancel previous (hot reload safety)
    await _sub?.cancel();
    _sub = stream.listen((qs) async {
      // If we subscribed to full snapshots, use docChanges to apply only diffs
      final current = Map<String, Venue>.fromEntries(
        (state.value ?? <Venue>[]).map((v) => MapEntry(v.id, v)),
      );

      if (qs.docChanges.isEmpty && lastSync == null) {
        // Defensive: if provider used full snapshot and no docChanges exposed,
        // rebuild from docs list.
        final all = qs.docs.map((d) => d.data()).toList(growable: false);
        await store.upsertMany(all);
        state = AsyncData(all);
        await store.setLastSync(DateTime.now());
        return;
      }

      // Apply changes
      for (final c in qs.docChanges) {
        switch (c.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            final v = c.doc.data();
            if (v != null) {
              await store.upsert(v);
              current[v.id] = v;
            }
            break;
          case DocumentChangeType.removed:
            final id = c.doc.id;
            await store.remove(id);
            current.remove(id);
            break;
        }
      }

      // Publish new list
      final list = current.values.toList(growable: false);
      state = AsyncData(list);

      // Move the checkpoint
      await store.setLastSync(DateTime.now());
    });
  }

}
