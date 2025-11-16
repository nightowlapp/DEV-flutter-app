// lib/data/services/users/user_finalize_service.dart (or your actual path)
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:nightowlcode/data/repositories/users/user_repository.dart';
import 'package:nightowlcode/models/users/user.dart' as model;
import 'package:nightowlcode/features/signup/presentation/sign_up_draft.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

class UserFinalizeService {
  UserFinalizeService(this._users, this._auth);

  final UserRepository _users;
  final fb.FirebaseAuth _auth;

  /// Creates or merges the Firestore user document with a complete payload.
  /// Assumes the Firebase Auth user already exists.
  Future<void> createFromDraft({
    required SignUpDraft draft,
    String? appVersion,
  }) async {
    final au = _auth.currentUser;
    if (au == null) throw StateError('No authenticated user');

    final email = (au.email ?? draft.email ?? '').trim().toLowerCase();
    final birth = draft.birthdate!;
    final gender = draft.gender!;

    final userName = draft.username!.trim();

    // Base user doc
    final user = model.User(
      id: au.uid,
      email: email,
      userName: userName,
      birthDate: birth,
      gender: gender,
      profilePictureUrl: draft.remotePhotoUrl ?? au.photoURL,
      appVersion: appVersion,
      isVerified: false,
    );

    // 1) Create user document
    await _users.create(user); // create-only

    // 2) Apply the same username logic as Settings:
    //    - set user_name_lc on the user doc
    //    - create /usernames/<lowercase> -> { uid: ... }
    //    - handle any old mapping if needed (here it's a new user so no old one)
    await _users.renameUsername(uid: au.uid, newUserName: userName);
  }
}
