// lib/data/repositories/venue_friend_cache.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:archive/archive_io.dart';

class MapStorage {
  MapStorage({
    this.maxEntries = 200,             // ~tiles across a few cities
    this.defaultTtl1 = const Duration(minutes: 15),
    String? namespace,
  }) : _ns = namespace ?? 'v1';

  static const Duration defaultTtl = Duration(minutes: 15);

  final int maxEntries;
  final Duration defaultTtl1;
  final String _ns;

  late final Future<Directory> _baseDir = _ensureDir();

  Future<Directory> _ensureDir() async {
    final dir = await getTemporaryDirectory();
    final base = Directory('${dir.path}/map_cache_$_ns');
    if (!await base.exists()) await base.create(recursive: true);
    return base;
  }

  String _fileNameForKey(String key) {
    final hash = md5.convert(utf8.encode(key)).toString();
    return '$hash.json.gz';
  }

  Future<File> _fileForKey(String key) async {
    final base = await _baseDir;
    return File('${base.path}/${_fileNameForKey(key)}');
  }

  Future<Map<String, dynamic>?> read(String key, {Duration? maxAge}) async {
    try {
      final f = await _fileForKey(key);
      if (!await f.exists()) return null;

      final stat = await f.stat();
      final age = DateTime.now().difference(stat.modified);
      final ttl = maxAge ?? defaultTtl;
      if (age > ttl) {
        // stale: don't delete immediately; allow background rewrite
        return null;
      }

      final bytes = await f.readAsBytes();
      final ungzipped = const GZipDecoder().decodeBytes(bytes);
      final jsonStr = utf8.decode(Uint8List.fromList(ungzipped));
      final map = json.decode(jsonStr) as Map<String, dynamic>;

      // touch file for LRU
      await f.setLastModified(DateTime.now());
      return map;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, Map<String, dynamic> value) async {
    try {
      final f = await _fileForKey(key);
      final jsonStr = json.encode(value);
      final gz = const GZipEncoder().encode(utf8.encode(jsonStr))!;
      await f.writeAsBytes(gz, flush: false);
      await _pruneIfNeeded();
    } catch (_) {
      // best-effort cache
    }
  }

  Future<void> clear() async {
    final base = await _baseDir;
    if (await base.exists()) {
      await for (final e in base.list()) {
        if (e is File) await e.delete();
      }
    }
  }

  Future<void> _pruneIfNeeded() async {
    final base = await _baseDir;
    final files = <File>[];
    await for (final e in base.list()) {
      if (e is File && e.path.endsWith('.json.gz')) files.add(e);
    }
    if (files.length <= maxEntries) return;

    // Sort by last modified ascending (oldest first), delete extras
    files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
    final toDelete = files.length - maxEntries;
    for (var i = 0; i < toDelete; i++) {
      try { await files[i].delete(); } catch (_) {}
    }
  }
}
