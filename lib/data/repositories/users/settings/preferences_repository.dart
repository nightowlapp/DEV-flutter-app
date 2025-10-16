import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/enums.dart' as model;

import '../../../firestore_paths.dart';


class PreferencesRepository {
  PreferencesRepository(this._db);
  final FirebaseFirestore _db;

  Future<void> updatePreferredVenueTypes({
    required String uid,
    required Set<model.VenueType> types,
  }) async {
    final list = types
      .where((e) => e != model.VenueType.unknown)
      .map((e) => e.name)
      .toList();

    final docRef = _db.doc(DocumentPaths.user(uid));
    await docRef.set({
      DocumentPaths.preferredVenueTypes: list,
      DocumentPaths.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // safe even if doc doesn’t exist
  }

  Future<void> updateMaxDistanceKm({
    required String uid,
    required double km,
  }) async {
    final docRef = _db.doc(DocumentPaths.user(uid));
    await docRef.set({
      DocumentPaths.maxDistanceKm: km,
      DocumentPaths.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
    return PreferencesRepository(FirebaseFirestore.instance);
  }
);

