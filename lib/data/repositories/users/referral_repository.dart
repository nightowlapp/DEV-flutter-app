import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightowlcode/data/providers/other_providers.dart'; // firestoreProvider

// ------------ Config ------------

class ReferralConfig {
  const ReferralConfig({
    required this.baseInviteUrl,
    required this.inviterAwardXp,
    required this.inviteeAwardXp,
    this.codeLength = 6,
  });

  final String baseInviteUrl;      // e.g. https://owlnight.com/invite
  final int inviterAwardXp;       // EXP for the inviter
  final int inviteeAwardXp;       // EXP for the invitee
  final int codeLength;            // default 6
}

final referralConfigProvider = Provider<ReferralConfig>((ref) {
  return const ReferralConfig(
    baseInviteUrl: 'https://owlnight.com/invite',
    inviterAwardXp: 100,
    inviteeAwardXp: 50,
    codeLength: 6,
  );
});

// ------------ Repository ------------

class ReferralRepository {
  ReferralRepository({
    required FirebaseFirestore db,
    required FirebaseAuth auth,
    required this.config,
  })  : _db = db,
        _auth = auth;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final ReferralConfig config;

  /// Returns the user’s invite code; generates + persists one if missing.
  Future<String> ensureInviteCodeForCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');

    final userRef = _db.collection('users').doc(uid);
    final snap = await userRef.get();
    final data = snap.data() ?? {};

    final existing = data['invite_code'] as String?;
    if (existing != null && existing.isNotEmpty) return existing;

    // Generate unique code and reserve in referralCodes
    final code = await _generateUniqueCode();
    await _db.runTransaction((tx) async {
      final codeRef = _db.collection('referral_codes').doc(code);
      final codeSnap = await tx.get(codeRef);
      if (codeSnap.exists) {
        throw StateError('Collision; retry'); // extremely unlikely due to pre-check
      }
      tx.set(codeRef, {
        'owner_uid': uid,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      tx.set(userRef, {
        'inviteCode': code,
      }, SetOptions(merge: true));
    });

    return code;
  }

  /// Builds the shareable invite link.
  String buildInviteLink(String code) {
    final base = config.baseInviteUrl.endsWith('/')
        ? config.baseInviteUrl.substring(0, config.baseInviteUrl.length - 1)
        : config.baseInviteUrl;
    return '$base/${code.toUpperCase()}';
  }

  /// Redeems a referral code. Returns (inviterUid, inviteeUid, awardedInviter, awardedInvitee).
  Future<ReferralResult> redeemCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (!_isCodeFormatValid(code)) {
      throw ArgumentError('Invalid code format');
    }

    final inviteeUid = _auth.currentUser?.uid;
    if (inviteeUid == null) throw StateError('Not signed in');

    final users = _db.collection('users');
    final codeRef = _db.collection('referralCodes').doc(code);
    final inviteeRef = users.doc(inviteeUid);

    return await _db.runTransaction<ReferralResult>((tx) async {
      final codeSnap = await tx.get(codeRef);
      if (!codeSnap.exists) {
        throw StateError('Code does not exist');
      }
      final inviterUid = codeSnap.data()!['ownerUid'] as String?;

      if (inviterUid == null || inviterUid.isEmpty) {
        throw StateError('Broken code owner');
      }
      if (inviterUid == inviteeUid) {
        throw StateError('You cannot refer yourself');
      }

      // Disallow multiple redemptions by the same user (global)
      final inviteeSnap = await tx.get(inviteeRef);
      final inviteeData = inviteeSnap.data();
      if (inviteeData != null && inviteeData['referredBy'] != null) {
        throw StateError('You have already been referred');
      }

      // Idempotency for this code specifically
      final redeemedRef =
      inviteeRef.collection('referrals_redeemed').doc(code);
      final redeemedSnap = await tx.get(redeemedRef);
      if (redeemedSnap.exists) {
        throw StateError('This code was already used by you');
      }

      // Update inviter
      final inviterRef = users.doc(inviterUid);
      tx.set(inviterRef, {
        'xp': FieldValue.increment(config.inviterAwardXp),
        'referralCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Update invitee (+ mark referredBy)
      tx.set(inviteeRef, {
        'xp': FieldValue.increment(config.inviteeAwardXp),
        'referredBy': inviterUid,
      }, SetOptions(merge: true));

      // Idempotency marker
      tx.set(redeemedRef, {
        'code': code,
        'inviterUid': inviterUid,
        'redeemedAt': FieldValue.serverTimestamp(),
      });

      // Optional global log
      final logRef = _db.collection('referrals').doc();
      tx.set(logRef, {
        'code': code,
        'inviterUid': inviterUid,
        'inviteeUid': inviteeUid,
        'awardedInviter': config.inviterAwardXp,
        'awardedInvitee': config.inviteeAwardXp,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return ReferralResult(
        inviterUid: inviterUid,
        inviteeUid: inviteeUid,
        awardedInviter: config.inviterAwardXp,
        awardedInvitee: config.inviteeAwardXp,
      );
    });
  }

  // ----- Helpers -----

  bool _isCodeFormatValid(String code) {
    final re = RegExp(r'^[A-Z0-9]{4,12}$'); // simple sanity check
    return re.hasMatch(code);
  }

  Future<String> _generateUniqueCode() async {
    const alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'; // no 0,1,I,O for readability
    final rnd = Random.secure();

    Future<String> gen() async {
      return List.generate(config.codeLength, (_) => alphabet[rnd.nextInt(alphabet.length)]).join();
    }

    // Try a few times; collisions are extremely unlikely
    for (var i = 0; i < 6; i++) {
      final candidate = await gen();
      final snap = await _db.collection('referralCodes').doc(candidate).get();
      if (!snap.exists) return candidate;
    }
    // Last resort: longer code
    return List.generate(config.codeLength + 2, (_) => alphabet[rnd.nextInt(alphabet.length)]).join();
  }
}

class ReferralResult {
  final String inviterUid;
  final String inviteeUid;
  final int awardedInviter;
  final int awardedInvitee;

  const ReferralResult({
    required this.inviterUid,
    required this.inviteeUid,
    required this.awardedInviter,
    required this.awardedInvitee,
  });
}

// ------------ Providers ------------

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepository(
    db: ref.watch(firestoreProvider),
    auth: FirebaseAuth.instance,
    config: ref.watch(referralConfigProvider),
  );
});

/// Ensures and exposes the current user's invite code.
final inviteCodeProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(referralRepositoryProvider);
  return repo.ensureInviteCodeForCurrentUser();
});

/// The shareable link. Depends on the invite code.
final inviteLinkProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(referralRepositoryProvider);
  final code = await ref.watch(inviteCodeProvider.future);
  return repo.buildInviteLink(code);
});

/// Live XP count of current user.
final myXpProvider = StreamProvider<int>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream<int>.empty();
  final db = ref.watch(firestoreProvider);
  return db.collection('users').doc(uid).snapshots().map((snap) {
    final data = snap.data();
    if (data == null) return 0;
    final xp = data['xp'];
    if (xp is int) return xp;
    if (xp is num) return xp.toInt();
    return 0;
  });
});
