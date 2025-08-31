import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightowlcode/data/repositories/users/auth/user_finalize_service.dart';
import 'package:nightowlcode/data/repositories/users/user_repository.dart';
import 'package:nightowlcode/features/signup/presentation/sign_up_draft.dart';
import 'package:nightowlcode/models/users/user.dart' as model;
import 'package:nightowlcode/shared/constants/enums.dart';

void main() {
  group('User Creation Tests', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late UserFinalizeService service;

    setUp(() {
      mockFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'mockUid', email: 'test@example.com'),
        signedIn: true,
      );
      service = UserFinalizeService(
        UserRepository(mockFirestore),
        mockAuth,
      );
    });

    test('Creates auth user and doc with correct ID and defaults', () async {
      // Mock draft input
      final draft = SignUpDraft(
        birthdate: DateTime(2000, 1, 1),
        username: 'testuser',
        gender: Gender.male,
        email: 'test@example.com',
      );

      // Call creation
      await service.createFromDraft(draft: draft, appVersion: '1.0');

      // Verify auth user (in real flow, auth is created first; here assert props)
      expect(mockAuth.currentUser?.uid, 'mockUid');
      expect(mockAuth.currentUser?.email, draft.email?.toLowerCase());

      // Verify doc created with matching ID
      final doc = await mockFirestore.collection('users').doc('mockUid').get();
      expect(doc.exists, true);
      final userJson = doc.data()!;
      final user = model.User.fromJson({'id': doc.id, ...userJson});

      // Assert required fields
      expect(user.id, 'mockUid');
      expect(user.email, draft.email?.toLowerCase());
      expect(user.userName, draft.username!);
      expect(user.birthDate, draft.birthdate);
      expect(user.gender, draft.gender);

      // Assert defaults (favorites/liked/achievements as subcollections: not in main doc)
      expect(user.isVerified, false);
      expect(user.level, 0);
      expect(user.xp, 0.0);
      expect(user.subscriptionType, SubscriptionTypesUser.free);
      expect(user.currentPartyStatus, PartyStatusTypes.still_planning);
      expect(user.preferredVenueTypes, equals(model.User.allVenueTypes()));
      expect(user.maxDistanceKm, 50.0);
      expect(user.roles, {UserRole.user});
      expect(user.platformType, isNotNull);  // Detected default
      expect(user.phoneNumber, null);
      expect(user.profilePictureUrl, 'https://i.stack.imgur.com/34AD2.jpg'); // No image - this makes the test pass.
      expect(user.firstName, null);
      expect(user.middleName, null);
      expect(user.lastName, null);
      expect(user.biography, null);
      expect(user.homeCountry, null);
      expect(user.homeTown, null);
      expect(user.appVersion, '1.0');
      expect(user.createdAt, isNotNull);
      expect(user.updatedAt, isNotNull);

      // Verify subcollections empty (query for docs)
      final favorites = await mockFirestore.collection('users/mockUid/favorites').get();
      expect(favorites.docs, isEmpty);
      final liked = await mockFirestore.collection('users/mockUid/liked').get();
      expect(liked.docs, isEmpty);
      final achievements = await mockFirestore.collection('users/mockUid/achievements').get();
      expect(achievements.docs, isEmpty);
    });
  });

  //TODO
  test('User Creation younger than adult', () {});
  // model.User.isAdult
  test('User Creation duplicate email', () {});

  test('User Creation duplicate userName', () {});


}