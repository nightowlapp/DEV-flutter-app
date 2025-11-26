// lib/data/repositories/users/role_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/firestore_paths/firestore_collections%20.dart';
import 'package:nightowlcode/data/firestore_paths/firestore_paths.dart';
import 'package:nightowlcode/data/providers/other_providers.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/models/users/user.dart' as model;

final db = FirebaseFirestore.instance;

class UserRoles {
  final bool isAdmin;
  final bool isOwner;
  final bool isTester;
  final bool isReviewer;

  const UserRoles({
    required this.isAdmin,
    required this.isOwner,
    required this.isTester,
    required this.isReviewer,
  });
}

/// Derives roles from the already-loaded `authUserProvider` user model.
/// No extra Firestore reads – just uses user.roles.
final userRolesProvider = Provider<UserRoles>((ref) {
  final authUserAsync = ref.watch(authUserProvider);

  return authUserAsync.maybeWhen(
    data: (model.User? user) {
      final roles = user?.roles ?? const <UserRole>{};

      return UserRoles(
        isAdmin: roles.contains(UserRole.admin),
        isOwner: roles.contains(UserRole.owner),
        isTester: roles.contains(UserRole.tester),
        isReviewer: roles.contains(UserRole.reviewer),
      );
    },
    orElse: () => const UserRoles(
      isAdmin: false,
      isOwner: false,
      isTester: false,
      isReviewer: false,
    ),
  );
});

/// Convenience boolean providers (optional)
final currentUserIsAdminProvider = Provider<bool>((ref) {
  return ref.watch(userRolesProvider).isAdmin;
});

final currentUserIsTesterProvider = Provider<bool>((ref) {
  return ref.watch(userRolesProvider).isTester;
});

final currentUserIsReviewerProvider = Provider<bool>((ref) {
  return ref.watch(userRolesProvider).isReviewer;
});

final currentUserIsOwnerProvider = Provider<bool>((ref) {
  return ref.watch(userRolesProvider).isOwner;
});

/// Local-first helper: only hits Firestore if reviewer is NOT in `localRoles`.
Future<void> addReviewerRoleToUserIfMissing({
  required String userId,
  required Iterable<UserRole> localRoles,
}) async {
  // purely local check – no Firestore reads here.
  if (localRoles.contains(UserRole.reviewer)) {
    return; // already reviewer → skip backend call.
  }

  // Not a reviewer yet → do one transaction to add it.
  await addReviewerRoleToUser(userId);
}

/// 🔥 Call this to add `reviewer` to a user's roles in Firestore.

Future<void> addReviewerRoleToUser(String userId) async {
  final docRef = db.collection(FirestoreCollections.users).doc(userId);

  await db.runTransaction((tx) async {
    final snap = await tx.get(docRef);
    if (!snap.exists) return;

    final data = snap.data() ?? <String, dynamic>{};

    // Read existing roles as strings, defaulting to empty list.
    final List<dynamic> rawRoles =
        (data[UserDocumentPaths.roles] as List?) ?? const [];
    final roles = rawRoles.map((e) => e.toString()).toSet();

    // Already reviewer → nothing to do.
    if (roles.contains(UserRole.reviewer.name)) return;

    // Add reviewer + write back.
    roles.add(UserRole.reviewer.name);
    tx.update(docRef, {
      UserDocumentPaths.roles: roles.toList(),
    });
  });
}
