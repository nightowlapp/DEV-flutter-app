// lib/shared/utility/storage_url.dart
import 'package:firebase_core/firebase_core.dart';

class StorageUrl {
  static String get _bucket {
    final b = Firebase.app().options.storageBucket; // comes from firebase_options.dart
    if (b == null || b.isEmpty) {
      throw StateError('No storageBucket configured in Firebase options.');
    }
    return b;
  }

  /// From `path/in/bucket.png` → public download URL
  static String fromPath(String path, {String? bucket}) {
    final b = bucket ?? _bucket;
    final p = Uri.encodeComponent(path.trim());
    return 'https://firebasestorage.googleapis.com/v0/b/$b/o/$p?alt=media';
  }

  /// From `gs://bucket/path/in/bucket.png`
  static String fromGsUrl(String gsUrl) {
    final uri = Uri.parse(gsUrl.trim());
    final b = uri.host.isNotEmpty ? uri.host : _bucket;
    final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    final p = Uri.encodeComponent(path);
    return 'https://firebasestorage.googleapis.com/v0/b/$b/o/$p?alt=media';
  }

  /// Accepts http(s), gs://, or relative path and returns a usable URL.
  static String normalize(String any) {
    final s = any.trim();
    if (s.isEmpty) return s;
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('gs://')) return fromGsUrl(s);
    return fromPath(s);
  }
}
