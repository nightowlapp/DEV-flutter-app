// lib/data/services/media/media_existence_provider.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/app_storage.dart';
import '../services/media_existence.dart';

final mediaExistenceProvider = Provider<MediaExistence>((ref) {
  final prefs =
      ref.watch(sharedPrefsProvider); // central instance (overridden in main)
  return MediaExistence(prefs: prefs, storage: FirebaseStorage.instance);
});
