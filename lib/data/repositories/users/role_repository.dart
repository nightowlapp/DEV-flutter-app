import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/firestore_paths.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

Future<bool> _hasRole(UserRole role) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection(DocumentPaths.users)
      .doc(user.uid)
      .get();

  final roles = doc.data()?[DocumentPaths.roles];

  if (roles is List) {
    return roles.contains(role.name);
  }

  return false;
}

Future<bool> checkIfAdmin() => _hasRole(UserRole.admin);
Future<bool> checkIfTester() => _hasRole(UserRole.tester);
Future<bool> checkIfReviewer() => _hasRole(UserRole.reviewer);

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

final userRolesProvider = FutureProvider<UserRoles>((ref) async {
  final isAdmin = await checkIfAdmin();
  final isOwner = await checkIfOwner();
  final isTester = await checkIfTester();
  final isReviewer = await checkIfReviewer();

  return UserRoles(
    isAdmin: isAdmin,
    isOwner: isOwner,
    isTester: isTester,
    isReviewer: isReviewer,
  );
});


Future<bool> checkIfOwner() => _hasRole(UserRole.owner); //TODO owner should be own array field - returns venueids.
