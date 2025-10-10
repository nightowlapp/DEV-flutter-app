import 'dart:async';
import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Allowed image extensions (order = preference)
const List<String> _imgExts = ['webp'];

/// Weekday canonical enum to keep things typed.
enum Weekdays { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

extension on Weekdays {
  String get name => describeEnum(this); // "monday" etc.

  static Weekdays? tryParse(String raw) {
    final l = raw.toLowerCase();
    for (final w in Weekdays.values) {
      if (w.name == l) return w;
    }
    // accept 3-letter forms: mon, tue, wed, thu, fri, sat, sun
    const short = {
      'mon': Weekdays.monday,
      'tue': Weekdays.tuesday,
      'wed': Weekdays.wednesday,
      'thu': Weekdays.thursday,
      'fri': Weekdays.friday,
      'sat': Weekdays.saturday,
      'sun': Weekdays.sunday,
    };
    if (l.length == 3 && short.containsKey(l)) return short[l];
    return null;
  }
}

/// Result bundle for a venue's media.
@immutable
class VenueMediaBundle {
  final String venueId;

  // Root files
  final String? coverUrl;
  final String? logoUrl;
  final String? defaultOfferUrl;
  final String? barCardPdfUrl;

  // Folders
  final List<String> moodImageUrls;
  final Map<Weekdays, String> dailyOfferUrls;

  const VenueMediaBundle({
    required this.venueId,
    this.coverUrl,
    this.logoUrl,
    this.defaultOfferUrl,
    this.barCardPdfUrl,
    this.moodImageUrls = const [],
    this.dailyOfferUrls = const {},
  });

  VenueMediaBundle copyWith({
    String? coverUrl,
    String? logoUrl,
    String? defaultOfferUrl,
    String? barCardPdfUrl,
    List<String>? moodImageUrls,
    Map<Weekdays, String>? dailyOfferUrls,
  }) {
    return VenueMediaBundle(
      venueId: venueId,
      coverUrl: coverUrl ?? this.coverUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      defaultOfferUrl: defaultOfferUrl ?? this.defaultOfferUrl,
      barCardPdfUrl: barCardPdfUrl ?? this.barCardPdfUrl,
      moodImageUrls: moodImageUrls ?? this.moodImageUrls,
      dailyOfferUrls: dailyOfferUrls ?? this.dailyOfferUrls,
    );
  }
}

/// Internal cache entry
class _CacheEntry {
  _CacheEntry(this.bundle, this.storedAt);
  final VenueMediaBundle bundle;
  final DateTime storedAt;
}

/// Lists and caches all media tied to a venue under:
/// gs://<bucket>/venue_images/<venueId>/
///
/// Expected layout:
/// - cover.(webp|jpg|jpeg|png)
/// - logo.(webp|jpg|jpeg|png)
/// - default_offer.(webp|jpg|jpeg|png)
/// - bar_card.pdf
/// - mood_images/*.(webp|jpg|jpeg|png)
/// - daily_offers/<weekday>.(webp|jpg|jpeg|png)  (monday..sunday or mon..sun)
class VenueMediaRepository {
  VenueMediaRepository({FirebaseStorage? storage, Duration? ttl})
      : _storage = storage ?? FirebaseStorage.instance,
        _ttl = ttl ?? const Duration(minutes: 15);

  final FirebaseStorage _storage;
  final Duration _ttl;

  static final _mem = <String, _CacheEntry>{}; // key = venueId

  Future<VenueMediaBundle> fetch(String venueId) async {
    // Serve fresh cache if present
    final c = _mem[venueId];
    final now = DateTime.now();
    if (c != null && now.difference(c.storedAt) < _ttl) return c.bundle;

    final baseRef = _storage.ref('venue_images/$venueId');

    // 1) Root items (single files)
    final root = await baseRef.listAll();
    final rootFiles = root.items;

    final cover = await _pickAndUrl(rootFiles, 'cover', _imgExts);
    final logo = await _pickAndUrl(rootFiles, 'logo', _imgExts);
    final defaultOffer =
        await _pickAndUrl(rootFiles, 'default_offer', _imgExts);
    final barCard = await _pickAndUrl(rootFiles, 'bar_card', const ['pdf']);

    // 2) mood_images/*
    final moodUrls = await _listUrls(baseRef.child('mood_images'), _imgExts);

    // 3) daily_offers/<weekday>.*
    final dailyUrls = await _listDaily(baseRef.child('daily_offers'));

    final bundle = VenueMediaBundle(
      venueId: venueId,
      coverUrl: cover,
      logoUrl: logo,
      defaultOfferUrl: defaultOffer,
      barCardPdfUrl: barCard,
      moodImageUrls: moodUrls,
      dailyOfferUrls: dailyUrls,
    );

    _mem[venueId] = _CacheEntry(bundle, now);
    return bundle;
  }

  /// Force refresh (bypass memory)
  Future<VenueMediaBundle> refresh(String venueId) async {
    _mem.remove(venueId);
    return fetch(venueId);
  }

  /// Clear whole cache (e.g. on sign out).
  void clear() => _mem.clear();

  // ---------- helpers ----------

  /// Pick a file by base name + preferred extensions, return download URL (or null).
  Future<String?> _pickAndUrl(
      List<Reference> files, String base, List<String> exts) async {
    // Partition root files by nameWithoutExt
    final grouped =
        groupBy<Reference, String>(files, (r) => _nameNoExt(r.name));
    final candidates = grouped[base] ?? const <Reference>[];
    if (candidates.isEmpty) return null;

    // Among all candidates, prefer by ext order.
    Reference? chosen;
    for (final e in exts) {
      chosen = candidates.firstWhereOrNull((r) => _ext(r.name) == e);
      if (chosen != null) break;
    }
    chosen ??= candidates.first; // fallback

    return chosen.getDownloadURL();
  }

  /// List a folder and return image URLs with concurrency.
  Future<List<String>> _listUrls(Reference folder, List<String> exts) async {
    // If folder doesn't exist, listAll() just returns empty results.
    final res = await folder.listAll();
    final imgs = res.items.where((r) => exts.contains(_ext(r.name))).toList();
    if (imgs.isEmpty) return const [];

    // Simple bounded concurrency to fetch download URLs quickly.
    const concurrency = 8;
    final it = imgs.iterator;
    final out = List<String>.filled(imgs.length, '', growable: false);
    int idx = 0;
    final lock = Object();

    Future<void> worker() async {
      while (true) {
        Reference? next;
        int myIndex = -1;
        // critical section
        // ignore: unnecessary_statements
        () {
          // poor-man's lock to keep indices stable
          synchronized(lock, () {
            if (!it.moveNext()) return;
            next = it.current;
            myIndex = idx++;
          });
        }();

        if (next == null) break;
        final url = await next!.getDownloadURL();
        out[myIndex] = url;
      }
    }

    final workers = List.generate(concurrency, (_) => worker());
    await Future.wait(workers);
    return out.where((e) => e.isNotEmpty).sorted(); // deterministic
  }

  /// Map daily_offers/<weekday>.(ext) -> Map<Weekday, url>
  Future<Map<Weekdays, String>> _listDaily(Reference folder) async {
    final res = await folder.listAll();
    if (res.items.isEmpty) return const {};

    // Group by weekday (ignore ext)
    final byDay = <Weekdays, List<Reference>>{};
    for (final r in res.items) {
      final base = _nameNoExt(r.name).toLowerCase();
      // final wd = Weekdays.tryparse(base);
      // if (wd == null) continue;
      // (byDay[wd] ??= <Reference>[]).add(r);
    }
    if (byDay.isEmpty) return const {};

    // Pick the best ext per weekday and fetch URL.
    final out = <Weekdays, String>{};
    for (final entry in byDay.entries) {
      final refs = entry.value;
      Reference? chosen;
      for (final e in _imgExts) {
        chosen = refs.firstWhereOrNull((r) => _ext(r.name) == e);
        if (chosen != null) break;
      }
      chosen ??= refs.first;
      out[entry.key] = await chosen.getDownloadURL();
    }

    return SplayTreeMap.from(
      out,
      (a, b) => a.index.compareTo(b.index), // keep Monday..Sunday order
    );
  }

  String _ext(String name) {
    final i = name.lastIndexOf('.');
    return i == -1 ? '' : name.substring(i + 1).toLowerCase();
  }

  String _nameNoExt(String name) {
    final i = name.lastIndexOf('.');
    return i == -1 ? name : name.substring(0, i);
  }
}

/// Tiny sync block for the simple concurrency helper above.
Future<T> synchronized<T>(Object lock, FutureOr<T> Function() action) async =>
    await action();
