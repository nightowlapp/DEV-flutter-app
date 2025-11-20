// data/repositories/users/personal_settings_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firestore_paths/firestore_paths.dart';

class PersonalSettingsRepository {
  PersonalSettingsRepository(this._db);
  final FirebaseFirestore _db;

  /// Writes home country/town on the USER doc.
  /// If [lastLat]/[lastLon] are provided, also upserts locations/{uid}.
  Future<void> setHomeLocation({
    required String uid,
    required String countryIso2,
    required String town,
    bool locked = false,
    double? lastLat,
    double? lastLon,
  }) async {
    final userRef = _db.doc(UserDocumentPaths.doc(uid));
    final locRef = _db.doc(LocationDocumentPaths.doc(uid));
    final batch = _db.batch();

    batch.update(userRef, {
      UserDocumentPaths.homeCountry: countryIso2.toLowerCase(),
      UserDocumentPaths.homeTown: town.toLowerCase(),
      UserDocumentPaths.homeLocationLocked: locked,
      UserDocumentPaths.updatedAt: FieldValue.serverTimestamp(),
    });

    if (lastLat != null && lastLon != null) {
      batch.set(
        locRef,
        {
          LocationDocumentPaths.lastKnownLat: lastLat,
          LocationDocumentPaths.lastKnownLon: lastLon,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  /// Only toggles the lock flag on the USER doc.
  Future<void> setHomeLocationLocked({
    required String uid,
    required bool locked,
  }) async {
    await _db.doc(UserDocumentPaths.doc(uid)).update({
      UserDocumentPaths.homeLocationLocked: locked,
      UserDocumentPaths.updatedAt: FieldValue.serverTimestamp(),
    });
  }

  /// Standalone writer for locations/{uid}.
  Future<void> setLastKnownLocation({
    required String uid,
    required double lat,
    required double lon,
  }) async {
    await _db.doc(LocationDocumentPaths.doc(uid)).set(
      {
        LocationDocumentPaths.lastKnownLat: lat,
        LocationDocumentPaths.lastKnownLon: lon,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

final personalSettingsRepositoryProvider =
Provider<PersonalSettingsRepository>(
      (ref) => PersonalSettingsRepository(FirebaseFirestore.instance),
);
