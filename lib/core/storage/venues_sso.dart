// lib/core/storage/venues_sso.dart
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:nightowlcode/data/repositories/venues/venue_converters.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/data/providers/other_providers.dart'; // firestoreProvider
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
  StreamSubscription<QuerySnapshot<Venue>>? _subDelta; // add/modify
  StreamSubscription<QuerySnapshot<Venue>>? _subRemovals; // delete-only
  KeepAliveLink? _keepAlive;

  @override
  Future<List<Venue>> build() async {
    _keepAlive ??= ref.keepAlive();
    final store = await ref.watch(venuesLocalStoreProvider.future);
    final db = ref.watch(firestoreProvider);

    // 1) Instant UI from local cache
    final local = await store.getAll();
    state = AsyncData(local);

    // 2) First run → full bootstrap from server and cache
    if (await store.isEmpty) {
      final all = await _fetchAllOnce(db);
      await store.upsertMany(all);
      await store.setLastSync(_maxUpdatedAt(all) ?? DateTime.now());
      state = AsyncData(all);
    }

    // 3) Start live sync (delta + removals)
    await _startLiveSync(db, store);

    ref.onDispose(() async {
      await _subDelta?.cancel();
      await _subRemovals?.cancel();
      _keepAlive?.close();
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

    final lastSync = await store.getLastSync();

    // --- DELTA stream: only added/modified since lastSync -------------------
    Stream<QuerySnapshot<Venue>> deltaStream;
    Query<Venue> deltaQ = col;
    try {
      if (lastSync != null) {
        deltaQ = deltaQ.where('updated_at',
            isGreaterThan: Timestamp.fromDate(lastSync));
      }
      deltaStream = deltaQ.snapshots();
    } catch (_) {
      deltaStream = col.snapshots();
    }

    await _subDelta?.cancel();
    _subDelta = deltaStream.listen((qs) async {
      final current = Map<String, Venue>.fromEntries(
        (state.value ?? const <Venue>[]).map((v) => MapEntry(v.id, v)),
      );

      DateTime? maxSeenUpdatedAt;

      // If docChanges is empty (some edge cases), rebuild from docs snapshot
      if (qs.docChanges.isEmpty && lastSync == null) {
        final all = qs.docs.map((d) => d.data()).toList(growable: false);
        await store.upsertMany(all);
        state = AsyncData(all);
        await store.setLastSync(_maxUpdatedAt(all) ?? DateTime.now());
        return;
      }

      for (final change in qs.docChanges) {
        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          final v = change.doc.data();
          if (v != null) {
            await store.upsert(v);
            current[v.id] = v;
            maxSeenUpdatedAt = _maxDate(maxSeenUpdatedAt, _extractUpdatedAt(v));
          }
        }
        // DO NOT process removals here; deletions are handled by the second stream.
      }

      final list = current.values.toList(growable: false);
      state = AsyncData(list);

      // Advance checkpoint using the newest updated_at we actually saw,
      // or use "now" conservatively.
      await store.setLastSync(maxSeenUpdatedAt ?? DateTime.now());
    }, onError: (e, st) async {
      state = AsyncError(e, st);
      try {
        final all = await _fetchAllOnce(db);
        await store.upsertMany(all);
        await store.setLastSync(_maxUpdatedAt(all) ?? DateTime.now());
        state = AsyncData(all);
      } catch (_) {}
    }, cancelOnError: false);

    // --- REMOVALS stream: full collection, but only react to removed --------
    await _subRemovals?.cancel();
    _subRemovals = col.snapshots().listen((qs) async {
      if (qs.docChanges.isEmpty) return;

      var changed = false;
      final current = Map<String, Venue>.fromEntries(
        (state.value ?? const <Venue>[]).map((v) => MapEntry(v.id, v)),
      );

      for (final change in qs.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          final id = change.doc.id;
          await store.remove(id);
          if (current.remove(id) != null) changed = true;
        }
      }

      if (changed) {
        state = AsyncData(current.values.toList(growable: false));
      }
    });
  }

  // ---------- helpers ----------

  DateTime? _extractUpdatedAt(Venue v) {
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

  /// Manual full refresh (e.g. pull-to-refresh)
  Future<void> forceFullResync() async {
    final db = ref.read(firestoreProvider);
    final store = await ref.read(venuesLocalStoreProvider.future);
    final all = await _fetchAllOnce(db);
    await store.upsertMany(all);
    await store.setLastSync(_maxUpdatedAt(all) ?? DateTime.now());
    state = AsyncData(all);
  }
}
