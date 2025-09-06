// Storage_repo.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageRepository { //TODO I want to move all storage in here DRY SCALE SOC.
  StorageRepository(this._storage);
  final FirebaseStorage _storage;

}
