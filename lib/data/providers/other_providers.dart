import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:nightowlcode/data/repositories/users/auth/auth_repository.dart';
import 'package:nightowlcode/data/repositories/users/auth/user_finalize_service.dart';
import 'package:nightowlcode/data/repositories/users/user_repository.dart';
import 'package:nightowlcode/data/services/users/profile_picture_service.dart';
import 'package:nightowlcode/models/users/user.dart' as model;

import '../../core/app_config.dart';
import '../repositories/storage_repository.dart';

//TODO Only keep "OTHER" providers in here.

// --- Low-level singletons ---
final firebaseAuthProvider =
    Provider<fb.FirebaseAuth>((ref) => fb.FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Current Firebase user (null when signed out)
final authStateProvider = StreamProvider<fb.User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

// --- Repos ---
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(firestoreProvider)),
);

final profilePictureServiceProvider = Provider<ProfilePictureService>((ref) {
  return ProfilePictureService(ref.read(firebaseStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final cfg = AppConfig.current;
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    users: ref.watch(userRepositoryProvider),
    googleServerClientId: cfg.googleServerClientId,
    googleIosClientId:
        cfg.googleIosClientId.isEmpty ? null : cfg.googleIosClientId,
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

final firebaseStorageProvider =
    Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);
final storageRepositoryProvider = Provider<StorageRepository>(
  (ref) => StorageRepository(ref.watch(firebaseStorageProvider)),
);
