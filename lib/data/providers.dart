import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:nightowlcode/data/repositories/users/auth/auth_repository.dart';
import 'package:nightowlcode/data/repositories/users/auth/user_finalize_service.dart';
import 'package:nightowlcode/data/repositories/users/user_repository.dart';
import 'package:nightowlcode/data/repositories/venues/venue_converters.dart';
import 'package:nightowlcode/data/repositories/venues/venue_repository.dart';
import 'package:nightowlcode/models/users/user.dart' as model;
import 'package:nightowlcode/models/venues/venue.dart';

import '../core/app_config.dart';
import '../models/venues/tag.dart';
import 'firestore_paths.dart';
import 'repositories/storage_repository.dart';
import 'repositories/venues/tag_repository.dart';

// --- Low-level singletons ---
final firebaseAuthProvider = Provider<fb.FirebaseAuth>((ref) => fb.FirebaseAuth.instance);
final firestoreProvider   = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Current Firebase user (null when signed out)
final authStateProvider = StreamProvider<fb.User?>(
      (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

// --- Repos ---
final userRepositoryProvider = Provider<UserRepository>(
      (ref) => UserRepository(ref.watch(firestoreProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final cfg = AppConfig.current;
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    users: ref.watch(userRepositoryProvider),
    googleServerClientId: cfg.googleServerClientId,
    googleIosClientId: cfg.googleIosClientId.isEmpty ? null : cfg.googleIosClientId,
  );
});

final authUserProvider = StreamProvider<model.User?>(
      (ref) => ref.watch(authRepositoryProvider).authUser$(),
);

final userFinalizeServiceProvider = Provider<UserFinalizeService>((ref) {
  final users = ref.watch(userRepositoryProvider);
  final auth = fb.FirebaseAuth.instance;
  return UserFinalizeService(users, auth);
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);
final storageRepositoryProvider = Provider<StorageRepository>(
      (ref) => StorageRepository(ref.watch(firebaseStorageProvider)),
);

final tagRepositoryProvider = Provider<TagRepository>(
      (ref) => TagRepository(db: ref.watch(firestoreProvider)),
);

// Fetch tags for a venue
final venueTagsProvider = FutureProvider.family<List<Tag>, List<String>>(
      (ref, tagIds) => ref.watch(tagRepositoryProvider).getByIds(tagIds),
);

// --- Venues ---
final venueRepositoryProvider = Provider<VenueRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return VenueRepository(db: db);
});

/// One-shot (if you need it)
final allVenuesFutureProvider = FutureProvider<List<Venue>>(
      (ref) => ref.watch(venueRepositoryProvider).getAll(),
  name: 'allVenuesFutureProvider',
);

/// Live stream of **all** venues (reactive)
// lib/data/providers.dart  (or where you define this)
final allVenuesStreamProvider = StreamProvider<List<Venue>>((ref) {
  final db = ref.watch(firestoreProvider);
  final col = db.collection(DocumentPaths.venues).withConverter<Venue>(
    fromFirestore: (snap, _) => VenueFirestore.fromSnapshot(snap), // ✅
    toFirestore: (v, _) => VenueFirestore.toMap(v),                // ✅
  );
  return col.snapshots().map((q) => q.docs.map((d) => d.data()).toList());
}, name: 'allVenuesStreamProvider');
