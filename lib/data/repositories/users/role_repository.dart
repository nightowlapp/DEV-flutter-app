// lib/data/repositories/users/role_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/providers/other_providers.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/models/users/user.dart' as model;

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

