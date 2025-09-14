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
final venuesSsoProvider = AsyncNotifierProvider<VenuesSso, List<Venue>>(VenuesSso.new);

class VenuesSso extends AsyncNotifier<List<Venue>> {
  StreamSubscription<QuerySnapshot<Venue>>? _sub;

  @override
  Future<List<Venue>> build() async {
    final store = await VenuesLocalStore.open();
    final db = ref.read(firestoreProvider);

    // 1) serve local immediately
    final local = await store.getAll();
    state = AsyncData(local);

    // 2) if local empty, do a one-shot full fetch (server) and cache
    if (await store.isEmpty) {
      final full = await _fetchAllOnce(db);
      await store.upsertMany(full);
      // checkpoint = max(updated_at) from full (or now if none)
      final maxTs = _maxUpdatedAt(full) ?? DateTime.now();
      await store.setLastSync(maxTs);
      state = AsyncData(full);
    }

    // 3) attach live delta stream (quiet background)
    await _startDeltaStream(db, store);

    ref.onDispose(() async {
      await _sub?.cancel();
      _sub = null;
    });

    return state.value ?? const <Venue>[];
  }

  Future<List<Venue>> _fetchAllOnce(FirebaseFirestore db) async {
    final col = db.collection(DocumentPaths.venues).withConverter<Venue>(
      fromFirestore: (snap, _) => VenueFirestore.fromSnapshot(snap),
      toFirestore: (v, _) => VenueFirestore.toMap(v),
    );

    // Order by updated_at ensures consistent paging if you ever add limits.
    final snap = await col.orderBy('updated_at', descending: false)
        .get(const GetOptions(source: Source.server));
    return snap.docs.map((d) => d.data()).toList(growable: false);
  }

  Future<void> _startDeltaStream(FirebaseFirestore db, VenuesLocalStore store) async {
    final col = db.collection(DocumentPaths.venues).withConverter<Venue>(
      fromFirestore: (snap, _) => VenueFirestore.fromSnapshot(snap),
      toFirestore: (v, _) => VenueFirestore.toMap(v),
    );

    final lastSync = await store.getLastSync();
    // Firestore requires orderBy on the inequality field.
    Query<Venue> q = col.orderBy('updated_at', descending: false);
    if (lastSync != null) {
      q = q.where('updated_at', isGreaterThan: Timestamp.fromDate(lastSync));
    }

    // cancel any previous sub (hot reload safety)
    await _sub?.cancel();

    _sub = q.snapshots().listen((qs) async {
      // Maintain a mutable map for minimal re-builds
      final current = <String, Venue>{
        for (final v in (state.value ?? const <Venue>[])) v.id: v,
      };

      // Track max updated_at we actually processed
      DateTime? maxServerUpdatedAt;

      for (final change in qs.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            final v = change.doc.data();
            if (v != null) {
              current[v.id] = v;
              await store.upsert(v);
              final u = v.updatedAt;
              if (u != null && (maxServerUpdatedAt == null || u.isAfter(maxServerUpdatedAt!))) {
                maxServerUpdatedAt = u;
              }
            }
            break;
          case DocumentChangeType.removed:
          // NOTE: removed is only emitted for full-collection listeners.
          // If you truly delete docs, prefer "soft delete" (see below).
            break;
        }
      }

      // Publish new list only if there were changes
      final nextList = current.values.toList(growable: false);
      state = AsyncData(nextList);

      // Advance checkpoint ONLY to the max server updated_at seen
      if (maxServerUpdatedAt != null) {
        await store.setLastSync(maxServerUpdatedAt!);
      }
    }, onError: (e, st) {
      // keep UI usable with cached data; optionally log
      // debugPrint('venues delta stream error: $e');
    });
  }

  DateTime? _maxUpdatedAt(Iterable<Venue> venues) {
    DateTime? m;
    for (final v in venues) {
      final u = v.updatedAt;
      if (u == null) continue;
      if (m == null || u.isAfter(m)) m = u;
    }
    return m;
  }
}

