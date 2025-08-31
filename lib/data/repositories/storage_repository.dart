import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageRepository {
  StorageRepository(this._storage);
  final FirebaseStorage _storage;

  Future<String> uploadUserProfileImage({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref('users/$uid/profile.webp');
    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/webp', cacheControl: 'public, max-age=3600'),
    );
    await task.whenComplete(() {});
    return await ref.getDownloadURL();
  }
}
