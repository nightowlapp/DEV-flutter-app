// lib/core/storage/venues_sso.dart
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:nightowlcode/data/repositories/venues/venue_converters.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/data/other_providers.dart'; // firestoreProvider
import 'package:nightowlcode/data/firestore_paths.dart'; // DocumentPaths.venues

// ----------------------------------------------------
// Local persistent store (Hive, one JSON blob per venue)
// ----------------------------------------------------

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
    return _box.keys.where((k) => k is String && k != _kLastSync).isEmpty;
  }

  Future<DateTime?> getLastSync() async {
    final iso = _box.get(_kLastSync) as String?;
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  Future<void> setLastSync(DateTime value) async {
    await _box.put(_kLastSync, value.toUtc().toIso8601String());
  }

  Future<void> upsert(Venue v) async {
    // FIX: persist the app JSON schema (symmetrical with Venue.fromJson)
    final cacheMap = <String, dynamic>{...v.toJson(), 'id': v.id};
    final safe = _jsonSafe(cacheMap) as Map<String, dynamic>;
    await _box.put(v.id, jsonEncode(safe));
  }

  Future<void> upsertMany(Iterable<Venue> venues) async {
    final entries = <String, String>{};
    for (final v in venues) {
      final cacheMap = <String, dynamic>{...v.toJson(), 'id': v.id};
      final safe = _jsonSafe(cacheMap) as Map<String, dynamic>;
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
      try {
        Map<String, dynamic>? map;
        if (raw is String) {
          map = jsonDecode(raw) as Map<String, dynamic>;
        } else if (raw is Map) {
          map = raw.cast<String, dynamic>(); // tolerate legacy writes
        }
        if (map == null) continue;
        final id = (map['id'] as String?) ?? key as String;
        result.add(Venue.fromJson(map, id));
      } catch (_) {
        // skip broken entry
      }
    }
    return result;
  }
}





dynamic _jsonSafe(dynamic v) {
  if (v == null) return null;
  if (v is GeoPoint) return {'lat': v.latitude, 'lng': v.longitude};
  if (v is Timestamp) return v.millisecondsSinceEpoch;
  if (v is DateTime) return v.toIso8601String();
  if (v is DocumentReference) return v.path;
  if (v is Iterable) return v.map(_jsonSafe).toList();
  if (v is Map) {
    return v.map((k, val) => MapEntry(k.toString(), _jsonSafe(val)));
  }
  return v; // num/bool/String
}

// --------------------------------------
// Riverpod: provider + live sync engine
// --------------------------------------

final venuesLocalStoreProvider = FutureProvider<VenuesLocalStore>((ref) async {
  return VenuesLocalStore.open();
});

final venuesSsoProvider =
AsyncNotifierProvider<VenuesSso, List<Venue>>(VenuesSso.new);

class VenuesSso extends AsyncNotifier<List<Venue>> {
  StreamSubscription<QuerySnapshot<Venue>>? _sub;
  KeepAliveLink? _keepAlive;

  @override
  Future<List<Venue>> build() async {
    _keepAlive ??= ref.keepAlive();
    final store = await ref.watch(venuesLocalStoreProvider.future);
    final db = ref.watch(firestoreProvider);

    // 1) Instant UI from local cache
    final local = await store.getAll();
    state = AsyncData(local);

    // 2) If empty -> fetch all once and cache
    if (await store.isEmpty) {
      final all = await _fetchAllOnce(db);
      await store.upsertMany(all);
      await store.setLastSync(_maxUpdatedAt(all) ?? DateTime.now());
      state = AsyncData(all);
    }

    // 3) Start live incremental sync
    await _startLiveSync(db, store);

    ref.onDispose(() async {
      await _sub?.cancel();
      _keepAlive?.close();
    });

    return state.value ?? <Venue>[];
  }

  Future<List<Venue>> _fetchAllOnce(FirebaseFirestore db) async {
    final col = db.collection(DocumentPaths.venues).withConverter<Venue>(
      fromFirestore: (snap, _) => VenueFirestore.fromSnapshot(snap),
      toFirestore: (v, _) => VenueFirestore.toMap(v),
    );

    // Always hit server for the bootstrap
    final snap = await col.get(const GetOptions(source: Source.server));
    return snap.docs.map((d) => d.data()).toList(growable: false);
  }

  Future<void> _startLiveSync(
      FirebaseFirestore db,
      VenuesLocalStore store,
      ) async {
    final col = db.collection(DocumentPaths.venues).withConverter<Venue>(
      fromFirestore: (snap, _) => VenueFirestore.fromSnapshot(snap),
      toFirestore: (v, _) => VenueFirestore.toMap(v),
    );

    final lastSync = await store.getLastSync();

    // Prefer delta updates by updated_at if available; fall back to full stream
    Query<Venue> baseQuery = col;
    Stream<QuerySnapshot<Venue>> stream;
    try {
      if (lastSync != null) {
        // Using isGreaterThan keeps the first emission small.
        baseQuery = baseQuery.where(
          'updated_at',
          isGreaterThan: Timestamp.fromDate(lastSync),
        );
      }
      stream = baseQuery.snapshots();
    } catch (_) {
      // If the field or index doesn't exist, fall back to full snapshots
      stream = col.snapshots();
    }

    await _sub?.cancel();
    _sub = stream.listen(
          (qs) async {
        final current = Map<String, Venue>.fromEntries(
          (state.value ?? const <Venue>[])
              .map((v) => MapEntry(v.id, v)),
        );

        DateTime? maxSeenUpdatedAt;

        // If docChanges is empty (can happen in some edge cases),
        // rebuild from docs snapshot.
        if (qs.docChanges.isEmpty && lastSync == null) {
          final all = qs.docs.map((d) => d.data()).toList(growable: false);
          await store.upsertMany(all);
          state = AsyncData(all);
          await store.setLastSync(_maxUpdatedAt(all) ?? DateTime.now());
          return;
        }

        for (final change in qs.docChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
            case DocumentChangeType.modified:
              final v = change.doc.data();
              if (v != null) {
                await store.upsert(v);
                current[v.id] = v;
                maxSeenUpdatedAt = _maxDate(
                  maxSeenUpdatedAt,
                  _extractUpdatedAt(v),
                );
              }
              break;
            case DocumentChangeType.removed:
              final id = change.doc.id;
              await store.remove(id);
              current.remove(id);
              break;
          }
        }

        // Publish new list to the UI
        final list = current.values.toList(growable: false);
        state = AsyncData(list);

        // Advance checkpoint using the newest updated_at we actually saw,
        // otherwise use "now" as a conservative fallback.
        await store.setLastSync(
          maxSeenUpdatedAt ?? DateTime.now(),
        );
      },
      onError: (e, st) async {
        // Optional: backoff + full refresh
        state = AsyncError(e, st);
        try {
          final all = await _fetchAllOnce(db);
          await store.upsertMany(all);
          await store.setLastSync(_maxUpdatedAt(all) ?? DateTime.now());
          state = AsyncData(all);
        } catch (_) {
          // keep error state; next tick might recover
        }
      },
      cancelOnError: false,
    );
  }

  /// Manual full refresh (e.g. pull-to-refresh)
  Future<void> forceFullResync() async {
    final db = ref.read(firestoreProvider);
    final store = await ref.read(venuesLocalStoreProvider.future);
    final all = await _fetchAllOnce(db);
    await store.upsertMany(all);
    await store.setLastSync(_maxUpdatedAt(all) ?? DateTime.now());
    state = AsyncData(all);
  }

  // ---------- helpers ----------

  DateTime? _extractUpdatedAt(Venue v) {
    // Try to read whatever the model/converter exposes.
    // (We go through the converter map to be resilient to types.)
    final map = VenueFirestore.toMap(v);
    final raw = map['updated_at'];
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  DateTime? _maxUpdatedAt(Iterable<Venue> items) {
    DateTime? maxDt;
    for (final v in items) {
      maxDt = _maxDate(maxDt, _extractUpdatedAt(v));
    }
    return maxDt;
  }

  DateTime? _maxDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
}
