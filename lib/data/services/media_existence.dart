// lib/data/services/media/media_existence.dart
import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/storage_url.dart';

class MediaExistenceResult {
  final bool exists;
  final String? downloadUrl;
  const MediaExistenceResult({required this.exists, this.downloadUrl});
}

class _CacheEntry {
  final bool exists;
  final int tsMillis;
  final String? url;
  _CacheEntry(this.exists, this.tsMillis, this.url);

  Map<String, dynamic> toJson() =>
      {'e': exists, 't': tsMillis, if (url != null) 'u': url};

  static _CacheEntry? fromJson(Map<String, dynamic>? m) {
    if (m == null) return null;
    return _CacheEntry(m['e'] == true, (m['t'] as num?)?.toInt() ?? 0, m['u'] as String?);
  }
}

/// Path/URL → existence + download URL, with LRU + TTL.
/// Positive TTL 24h; negative TTL 10m (tunable).
class MediaExistence {
  MediaExistence({
    required SharedPreferences prefs,
    FirebaseStorage? storage,
    Duration? positiveTtl,
    Duration? negativeTtl,
    int? maxEntries,
  })  : _prefs = prefs,
        _storage = storage ?? FirebaseStorage.instance,
        _positiveTtl = positiveTtl ?? const Duration(hours: 24),
        _negativeTtl = negativeTtl ?? const Duration(minutes: 10),
        _maxEntries = maxEntries ?? 512;


  final SharedPreferences _prefs;
  final FirebaseStorage _storage;
  final Duration _positiveTtl;
  final Duration _negativeTtl;
  final int _maxEntries;

  final _mem = <String, _CacheEntry>{};
  bool _loaded = false;
  static const _prefsKey = 'media_existence_cache_v1';

  Future<void> _loadPrefs() async {
    if (_loaded) return;
    _loaded = true;
    final raw = _prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final Map<String, dynamic> m = json.decode(raw);
      for (final e in m.entries) {
        final ce = _CacheEntry.fromJson((e.value as Map).cast<String, dynamic>());
        if (ce != null) _mem[e.key] = ce;
      }
    } catch (_) {}
  }

  Future<void> _flushPrefs() async {
    if (_mem.length > _maxEntries) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final sorted = _mem.entries.sortedBy<num>((e) => (now - e.value.tsMillis));
      final toRemove = _mem.length - _maxEntries;
      for (var i = 0; i < toRemove; i++) {
        _mem.remove(sorted[i].key);
      }
    }
    final map = _mem.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs.setString(_prefsKey, json.encode(map));
  }

  bool _looksLikeUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://') || s.startsWith('gs://');

  String _cacheKeyOf(String refOrUrl) => refOrUrl.trim();

  bool _isFresh(_CacheEntry e, Duration ttl) {
    final age = DateTime.now().millisecondsSinceEpoch - e.tsMillis;
    return age >= 0 && age <= ttl.inMilliseconds;
  }

  Future<void> invalidate(String refOrUrl) async {
    await _loadPrefs();
    _mem.remove(_cacheKeyOf(refOrUrl));
    await _flushPrefs();
  }
  Future<MediaExistenceResult> check(String refOrUrl, {bool force = false}) async {
    await _loadPrefs();
    final raw = refOrUrl.trim();
    if (raw.isEmpty) return const MediaExistenceResult(exists: false);

    final cached = _mem[raw];
    if (!force && cached != null) {
      final ttl = cached.exists ? _positiveTtl : _negativeTtl;
      if (_isFresh(cached, ttl)) {
        return MediaExistenceResult(exists: cached.exists, downloadUrl: cached.url);
      }
    }

    // Build a deterministic public URL (no network call).
    final directUrl = StorageUrl.normalize(raw);

    // Trust direct URLs to avoid startup stutter. Let the image widget handle 404s with fallback.
    final entry = _CacheEntry(true, DateTime.now().millisecondsSinceEpoch, directUrl);
    _mem[raw] = entry;
    await _flushPrefs();
    return MediaExistenceResult(exists: true, downloadUrl: directUrl);
  }


  /// Batch with limited concurrency.
  Future<Map<String, MediaExistenceResult>> checkAll(
      Iterable<String> refsOrUrls, {
        int concurrency = 6,
        bool force = false,
      }) async {
    final out = <String, MediaExistenceResult>{};
    final it = refsOrUrls.iterator;

    Future<void> worker() async {
      while (true) {
        if (!it.moveNext()) break;
        final key = it.current;
        out[key] = await check(key, force: force);
      }
    }

    final workers = List.generate(concurrency, (_) => worker());
    await Future.wait(workers);
    return out;
  }
}

class VenueMediaHealth {
  final bool coverExists;
  final bool logoExists;
  final int moodCount;
  final String? coverUrl;
  final String? logoUrl;

  const VenueMediaHealth({
    required this.coverExists,
    required this.logoExists,
    required this.moodCount,
    this.coverUrl,
    this.logoUrl,
  });
}

abstract class VenueLike {
  String get id;
  String? get coverImageUrl;
  String? get logoUrl;
  List<String> get moodImageUrls;
}

class VenueMediaService {
  VenueMediaService(this._media);
  final MediaExistence _media;

  Future<VenueMediaHealth> probe({
    required String? coverRefOrUrl,
    required String? logoRefOrUrl,
    required List<String> moodRefsOrUrls,
    bool force = false,
  }) async {
    final toCheck = <String>[];
    if (coverRefOrUrl?.isNotEmpty == true) toCheck.add(coverRefOrUrl!);
    if (logoRefOrUrl?.isNotEmpty == true) toCheck.add(logoRefOrUrl!);
    toCheck.addAll(moodRefsOrUrls.where((e) => e.isNotEmpty));

    final results = await _media.checkAll(toCheck, force: force);
    final cover = (coverRefOrUrl != null && results.containsKey(coverRefOrUrl))
        ? results[coverRefOrUrl]!
        : const MediaExistenceResult(exists: false);
    final logo = (logoRefOrUrl != null && results.containsKey(logoRefOrUrl))
        ? results[logoRefOrUrl]!
        : const MediaExistenceResult(exists: false);

    var mood = 0;
    for (final m in moodRefsOrUrls) {
      if (m.isEmpty) continue;
      final r = results[m];
      if (r?.exists == true) mood++;
    }

    return VenueMediaHealth(
      coverExists: cover.exists,
      logoExists: logo.exists,
      moodCount: mood,
      coverUrl: cover.downloadUrl,
      logoUrl: logo.downloadUrl,
    );
  }
}
extension VenueMediaServiceProgressive on VenueMediaService {
  Stream<MapEntry<String, VenueMediaHealth>> probeVenuesProgressive(
      Iterable<VenueLike> venues, {
        int concurrency = 12,
        bool force = false,
      }) {
    final controller = StreamController<MapEntry<String, VenueMediaHealth>>.broadcast();
    final queue = Queue<VenueLike>()..addAll(venues);

    Future<void> worker() async {
      while (queue.isNotEmpty && !controller.isClosed) {
        final v = queue.removeFirst();
        try {
          final h = await probe(
            coverRefOrUrl: v.coverImageUrl,
            logoRefOrUrl: v.logoUrl,
            moodRefsOrUrls: v.moodImageUrls,
            force: force,
          );
          controller.add(MapEntry(v.id, h));
        } catch (e, stack) {
          print('Probe error for venue ${v.id}: $e\n$stack');
          // Emit default health for failed probes
          controller.add(MapEntry(
            v.id,
            VenueMediaHealth(
              coverExists: false,
              logoExists: false,
              moodCount: 0,
              coverUrl: v.coverImageUrl,
              logoUrl: v.logoUrl,
            ),
          ));
        }
      }
    }

    () async {
      final workers = List.generate(concurrency, (_) => worker());
      await Future.wait(workers);
      // if (!controller.isGoogleApiManager closed) await controller.close();
    }();

    return controller.stream;
  }
}