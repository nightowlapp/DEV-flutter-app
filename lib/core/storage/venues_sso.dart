// lib/core/storage/venues_sso.dart
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/data/providers/other_providers.dart';
import 'package:nightowlcode/data/firestore_paths/firestore_paths.dart';

import '../../data/services/location/location_providers.dart';
import '../../features/map/presentation/venues_fc.dart';
import '../../shared/utility/distance.dart';
import '../../shared/utility/lat_lng.dart';
import '../app_config.dart';
import 'app_storage.dart';

// ----------------------------------------------------
// Local persistent store (Hive, one JSON blob per venue)
// ----------------------------------------------------

extension VenuesLocalStoreStreaming on VenuesLocalStore {
  Stream<List<Venue>> streamAllIncremental({
    LatLng? origin,
    int batchSize = 24,
  }) async* {
    final now = DateTime.now();
    final keys = _box.keys
        .where((k) => k is String && k != VenuesLocalStore.kLastSyncKey)
        .cast<String>()
        .toList(growable: false);

    double _dist(Venue v) =>
        origin == null ? double.infinity : Distance.metersLatLng(origin, v.entry);

    int _cmp(Venue a, Venue b) {
      final oa = a.isOpenNow(now) ? 0 : 1;
      final ob = b.isOpenNow(now) ? 0 : 1;
      if (oa != ob) return oa - ob;
      final da = _dist(a), db = _dist(b);
      if (da != db) return da.compareTo(db);
      final ra = a.rating ?? 0, rb = b.rating ?? 0;
      final r = rb.compareTo(ra);
      if (r != 0) return r;
      return a.displayName.compareTo(b.displayName);
    }

    final acc = <Venue>[];
    var i = 0;

    for (final key in keys) {
      final raw = _box.get(key);
      try {
        Map<String, dynamic>? map;
        if (raw is String) {
          map = jsonDecode(raw) as Map<String, dynamic>;
        } else if (raw is Map) {
          map = raw.cast<String, dynamic>(); // tolerate legacy writes
        }
        if (map == null) continue;
        final id = (map['id'] as String?) ?? key;
        final v = Venue.fromJson(map, id);
        acc.add(v);
      } catch (_) {
        // skip broken entry
      }

      i++;
      final shouldEmit = i <= 4 || (i % batchSize == 0);
      if (shouldEmit) {
        final list = List<Venue>.from(acc)..sort(_cmp);
        yield list;
        await Future.delayed(Duration.zero);
      }
    }

    final list = List<Venue>.from(acc)..sort(_cmp);
    yield list;
  }
}

class VenuesLocalStore {
  /// Box name is scoped per APP_ENV so dev/prod never share venue cache.
  static String get _boxName => EnvStorage.hiveBoxName('venues_box');

  /// Exposed for streaming extension.
  static const String kLastSyncKey = '__lastSyncIso';

  VenuesLocalStore._(this._box);
  final Box _box;

  static Future<VenuesLocalStore> open() async {
    final box = await Hive.openBox(_boxName);
    return VenuesLocalStore._(box);
  }

  Future<bool> get isEmpty async {
    return _box.keys.where((k) => k is String && k != kLastSyncKey).isEmpty;
  }

  Future<DateTime?> getLastSync() async {
    final iso = _box.get(kLastSyncKey) as String?;
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  Future<void> setLastSync(DateTime value) async {
    await _box.put(kLastSyncKey, value.toUtc().toIso8601String());
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
      if (key == kLastSyncKey) continue;
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
final venuesLocalBootDoneProvider = StateProvider<bool>((_) => false); // When finished fetching all from hive

final venuesLocalStoreProvider = FutureProvider<VenuesLocalStore>((ref) async {
    return VenuesLocalStore.open();
  }
);
///True provider with all venues from local.
final venuesSsoProvider =
  AsyncNotifierProvider<VenuesSso, List<Venue>>(VenuesSso.new);

class VenuesSso extends AsyncNotifier<List<Venue>> {
  StreamSubscription<List<Venue>>? _subLocal;
  StreamSubscription<QuerySnapshot<Venue>>? _subDelta;
  StreamSubscription<QuerySnapshot<Venue>>? _subRemovals;
  KeepAliveLink? _keepAlive;

  LatLng? _origin;

  @override
  Future<List<Venue>> build() async {
    ref.read(venuesLocalBootDoneProvider.notifier).state = false;
    _keepAlive ??= ref.keepAlive();
    final store = await ref.watch(venuesLocalStoreProvider.future);
    final db = ref.watch(firestoreProvider);

    // Start empty
    state = const AsyncData(<Venue>[]);

    // Seed origin from prefs (non-blocking)
    try {
      final prefs = ref.read(sharedPrefsProvider);
      final lat = prefs.getDouble('last_lat');
      final lng = prefs.getDouble('last_lng');
      if (lat != null && lng != null) _origin = LatLng(lat, lng);
    }
    catch (_) {}

    // Re-sort when a new location arrives (don’t rebuild the whole world)
    ref.listen(latLngSafeStreamProvider, (prev, next) {
      final p = next.maybeWhen(data: (v) => v, orElse: () => null);
      if (p == null) return;

      // Only persist if we moved > ~25m (or use time-based throttle)
      final prefs = ref.read(sharedPrefsProvider);
      final prevLat = prefs.getDouble('last_lat');
      final prevLng = prefs.getDouble('last_lng');
      if (prevLat != null && prevLng != null) {
        final moved = Distance.metersLatLng(LatLng(prevLat,prevLng), p);
        if (moved < 50) return;
      }
      prefs.setDouble('last_lat', p.lat);
      prefs.setDouble('last_lng', p.lng);
    });

// 1) Progressive local boot
    await _subLocal?.cancel();
    _subLocal = store
        .streamAllIncremental(origin: _origin, batchSize: 24)
        .listen((partial) {
      state = AsyncData(_sorted(partial));
    }, onError: (e, st) {
      state = AsyncError(e, st);
    }, onDone: () {
      // ✅ local cache fully scanned (final emit already happened)
      ref.read(venuesLocalBootDoneProvider.notifier).state = true;
    });

    // 2) First-ever run
    if (await store.isEmpty) {
      final all = await _fetchAllOnce(db);
      await store.upsertMany(all);
      await store.setLastSync(_maxUpdatedAt(all) ?? DateTime.now());
      state = AsyncData(_sorted(all));
    }

    // 3) Live sync
    await _startLiveSync(db, store);

    ref.onDispose(() async {
        await _subLocal?.cancel();
        await _subDelta?.cancel();
        await _subRemovals?.cancel();
        _keepAlive?.close();
      }
    );

    return state.value ?? <Venue>[];
  }

  // Sort helper: open now first, then distance (if _origin), then rating desc, name asc.
  List<Venue> _sorted(List<Venue> input) {
    final now = DateTime.now();
    int cmp(Venue a, Venue b) {
      final oa = a.isOpenNow(now) ? 0 : 1;
      final ob = b.isOpenNow(now) ? 0 : 1;
      if (oa != ob) return oa - ob;

      if (_origin != null) {
        final da = Distance.metersLatLng(_origin!, a.entry);
        final db = Distance.metersLatLng(_origin!, b.entry);
        if (da != db) return da.compareTo(db);
      }

      final ra = a.rating ?? 0, rb = b.rating ?? 0;
      final r = rb.compareTo(ra);
      if (r != 0) return r;
      return a.displayName.compareTo(b.displayName);
    }

    final out = List<Venue>.from(input);
    out.sort(cmp);
    return out;
  }

  // In _startLiveSync, sort before publishing:
  Future<void> _startLiveSync(FirebaseFirestore db, VenuesLocalStore store) async {
    // Important that this only runs on updated_at. If that field is wrong, gone or otherwise fucked shit wont work.
    final col = db.collection(FirestoreCollections.venues).withConverter<Venue>(
      fromFirestore: (snap, _) => VenueFirestore.fromSnapshot(snap),
      toFirestore: (v, _) => VenueFirestore.toMap(v),
    );

    final lastSync = await store.getLastSync();

    Stream<QuerySnapshot<Venue>> deltaStream;
    Query<Venue> deltaQ = col;
    try {
      if (lastSync != null) {
        deltaQ = deltaQ.where(FirestoreFields.updatedAt, isGreaterThan: Timestamp.fromDate(lastSync));
      }
      deltaStream = deltaQ.snapshots();
    }
    catch (_) {
      deltaStream = col.snapshots();
    }

    await _subDelta?.cancel();
    _subDelta = deltaStream.listen((qs) async {
        final current = Map<String, Venue>.fromEntries(
          (state.value ?? const <Venue>[]).map((v) => MapEntry(v.id, v)),
        );
        DateTime? maxSeenUpdatedAt;

        if (qs.docChanges.isEmpty && lastSync == null) {
          final all = qs.docs.map((d) => d.data()).toList(growable: false);
          await store.upsertMany(all);
          state = AsyncData(_sorted(all));
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
        }

        final list = current.values.toList(growable: false);
        state = AsyncData(_sorted(list));
        await store.setLastSync(maxSeenUpdatedAt ?? DateTime.now());
      }, onError: (e, st) async {
        state = AsyncError(e, st);
        try {
          final all = await _fetchAllOnce(db);
          await store.upsertMany(all);
          await store.setLastSync(_maxUpdatedAt(all) ?? DateTime.now());
          state = AsyncData(_sorted(all));
        }
        catch (_) {}
      }, cancelOnError: false);

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
          state = AsyncData(_sorted(current.values.toList(growable: false)));
        }
      }
    );
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
    state = AsyncData(_sorted(all)); // ← sorted here
  }
}

Future<List<Venue>> _fetchAllOnce(FirebaseFirestore db) async { // TODO should not be called loosely
  final col = db.collection(FirestoreCollections.venues).withConverter<Venue>
    (fromFirestore: (snap, _) => VenueFirestore.fromSnapshot(snap),
    toFirestore: (v, _) => VenueFirestore.toMap(v), );
  final snap = await col.get(const GetOptions(source: Source.server));
  return snap.docs.map((d) => d.data()).toList(growable: false);
}

