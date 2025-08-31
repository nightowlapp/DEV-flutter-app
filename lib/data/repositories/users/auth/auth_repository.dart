// lib/data/repositories/users/auth_repository.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../user_repository.dart';
import 'package:nightowlcode/models/users/user.dart' as model;

class AuthRepository {
  AuthRepository({
    required fb.FirebaseAuth auth,
    required UserRepository users,
    required String googleServerClientId,
    String? googleIosClientId,
  })  : _auth = auth,
        _users = users,
        _serverClientId = googleServerClientId,
        _iosClientId = googleIosClientId {
    // Set persistence to LOCAL on initialization
    // _setPersistence();
  }

  final fb.FirebaseAuth _auth;
  final UserRepository _users;

  final String _serverClientId; // Web OAuth client ID
  final String? _iosClientId;   // iOS client ID (optional)

  bool _googleReady = false;

  // Future<void> _setPersistence() async {
  //   await _auth.setPersistence(fb.Persistence.LOCAL);
  // }

  Future<void> _ensureGoogleInit() async {
    if (_googleReady || kIsWeb) { _googleReady = true; return; }
    if (_serverClientId.isEmpty) {
      throw StateError('GOOGLE_SERVER_CLIENT_ID is empty on Android.');
    }
    await GoogleSignIn.instance.initialize(
      serverClientId: _serverClientId,
      clientId: _iosClientId, // null on Android is fine
    );
    try { await GoogleSignIn.instance.attemptLightweightAuthentication(); } catch (_) {}
    _googleReady = true;
  }

  /// Optional: call at app start for snappier first tap.
  Future<void> prewarmGoogle() => _ensureGoogleInit();

  fb.User? get firebaseUser => _auth.currentUser;
  Stream<fb.User?> authState() => _auth.authStateChanges();

  Future<fb.User?> signInWithGoogle() async {
    if (kIsWeb) {
      final cred = await _auth.signInWithPopup(fb.GoogleAuthProvider());
      final u = cred.user;
      return u;
    }
    await _ensureGoogleInit();
    final account = await GoogleSignIn.instance.authenticate();
    if (account == null) return null;
    final idToken = (await account.authentication).idToken;
    final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
    final userCred = await _auth.signInWithCredential(credential);
    final u = userCred.user;
    return u;
  }

  Future<fb.User?> signInWithApple() async {
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
    final oauth = fb.OAuthProvider('apple.com').credential(
      idToken: apple.identityToken,
      accessToken: apple.authorizationCode,
    );
    final cred = await _auth.signInWithCredential(oauth);
    final u = cred.user;
    return u;
  }

  Future<fb.User?> signUpWithEmailPassword(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(), password: password,
    );
    final u = cred.user;
    return u;
  }

  Future<fb.User?> signInWithEmailPassword(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(), password: password,
    );
    final u = cred.user;
    return u;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) { try { await GoogleSignIn.instance.signOut(); } catch (_) {} }
  }

  Stream<model.User?> authUser$() {
    return _auth.authStateChanges().asyncExpand((fb.User? au) async* {
      if (au == null) { yield null; return; }
      yield await _users.getById(au.uid);
      yield* _users.watchById(au.uid);
    });
  }


}
