import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';

/// Lists and caches Storage items under a folder prefix.
/// Example folder: 'venue_images/abc123/mood_images/'
class MoodRepository {
  MoodRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  // Simple in-memory cache by folder path.
  static final _memCache = <String, _CacheEntry>{};

  /// List all image download URLs under [folder], paged, then cached.
  /// For very large folders, prefer [listPage] with your own paging UI.
  Future<List<String>> listAllUrls(String folder,
      {Duration ttl = const Duration(minutes: 15)}) async {
    final now = DateTime.now();
    final cached = _memCache[folder];
    if (cached != null && now.difference(cached.storedAt) < ttl) {
      return cached.urls;
    }

    final ref = _storage.ref(_normalize(folder));
    final urls = <String>[];
    String? token;
    do {
      final res =
          await ref.list(ListOptions(maxResults: 1000, pageToken: token));
      // Filter files (ignore subfolders if any)
      for (final item in res.items) {
        // Minor extension filter (optional)
        final name = item.name.toLowerCase();
        if (name.endsWith('.webp') ||
            name.endsWith('.jpg') ||
            name.endsWith('.jpeg') ||
            name.endsWith('.png')) {
          urls.add(await item.getDownloadURL());
        }
      }
      token = res.nextPageToken;
    } while (token != null);

    urls.sort(); // deterministic order by object name
    _memCache[folder] = _CacheEntry(urls, now);
    return urls;
  }

  /// Page through a folder for large collections (build your own paging UI).
  Future<({List<String> urls, String? nextPageToken})> listPage(
    String folder, {
    String? pageToken,
    int pageSize = 60,
  }) async {
    final ref = _storage.ref(_normalize(folder));
    final res =
        await ref.list(ListOptions(maxResults: pageSize, pageToken: pageToken));
    final urls = <String>[];
    for (final item in res.items) {
      final name = item.name.toLowerCase();
      if (name.endsWith('.webp')) urls.add(await item.getDownloadURL());
    }
    return (urls: urls, nextPageToken: res.nextPageToken);
  }

  String _normalize(String folder) {
    if (folder.isEmpty) return folder;
    return folder.endsWith('/') ? folder : '$folder/';
  }
}

class _CacheEntry {
  _CacheEntry(this.urls, this.storedAt);
  final List<String> urls;
  final DateTime storedAt;
}
