// test/features/settings/settings_change_test.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:nightowlcode/features/settings/widgets/settings_screen.dart';
import 'package:nightowlcode/data/providers/other_providers.dart';
import 'package:nightowlcode/data/repositories/users/settings/preferences_repository.dart';
import 'package:nightowlcode/data/repositories/users/settings/personal_settings_repository.dart';
import 'package:nightowlcode/data/repositories/users/user_repository.dart'
    hide userRepositoryProvider;
import 'package:nightowlcode/models/users/user.dart' as app_user;
import 'package:nightowlcode/models/users/phone_number.dart' as phone;
import 'package:nightowlcode/shared/constants/enums.dart';

// Mocks (unchanged)
class MockPreferencesRepository extends Mock implements PreferencesRepository {}
class MockPersonalSettingsRepository extends Mock implements PersonalSettingsRepository {}
class MockUserRepository extends Mock implements UserRepository {}
class MockAppUser extends Mock implements app_user.User {}

// Simplified text finder
Finder findTextLoose(String needle) {
  final target = needle.trim();
  return find.text(target, findRichText: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(<VenueType>{});
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> _prewarmedContainer({
    required PreferencesRepository prefsRepo,
    required PersonalSettingsRepository personalRepo,
    required UserRepository userRepo,
    required MockFirebaseAuth mockAuth,
    required app_user.User user,
  }) async {
    final container = ProviderContainer(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(prefsRepo),
        personalSettingsRepositoryProvider.overrideWithValue(personalRepo),
        userRepositoryProvider.overrideWithValue(userRepo),
        firebaseAuthProvider.overrideWithValue(mockAuth),
        authUserProvider.overrideWith((ref) => Stream<app_user.User?>.value(user)),
      ],
    );
    await container.read(authUserProvider.future);
    return container;
  }

  group('SettingsScreen -> fetch + upsert', () {
    testWidgets('Preferred venue types -> repo + SharedPreferences', (tester) async {
      // Setup
      final prefsRepo = MockPreferencesRepository();
      final personalRepo = MockPersonalSettingsRepository();
      final userRepo = MockUserRepository();

      when(() => prefsRepo.updatePreferredVenueTypes(
        uid: any(named: 'uid'),
        types: any(named: 'types'),
      )).thenAnswer((_) async {});

      final fbUser = MockUser(
        uid: 'uid_123',
        email: 'me@example.com',
        displayName: 'Tester',
        phoneNumber: '+4512345678',
      );
      final mockAuth = MockFirebaseAuth(mockUser: fbUser, signedIn: true);

      final appUser = MockAppUser();
      when(() => appUser.homeCountryCode).thenReturn('DK');
      when(() => appUser.homeTown).thenReturn('copenhagen');
      when(() => appUser.homeLocationLocked).thenReturn(true);
      when(() => appUser.isVerified).thenReturn(false);
      when(() => appUser.roles).thenReturn(<UserRole>{UserRole.user});
      when(() => appUser.subscriptionType).thenReturn(SubscriptionTypesUser.free);
      when(() => appUser.preferredVenueTypes)
          .thenReturn(<VenueType>{VenueType.bar, VenueType.club, VenueType.pub});
      when(() => appUser.maxDistanceKm).thenReturn(50);
      when(() => appUser.email).thenReturn('me@example.com');
      when(() => appUser.userName).thenReturn('tester');
      when(() => appUser.firstName).thenReturn('Test');
      when(() => appUser.middleName).thenReturn('');
      when(() => appUser.lastName).thenReturn('User');
      when(() => appUser.displayFullName).thenReturn('Test User');
      when(() => appUser.birthDate).thenReturn(DateTime(1990, 1, 1));
      when(() => appUser.phoneNumber).thenReturn(
        phone.PhoneNumber.tryParse('+4512345678', iso2: 'DK', callingCode: '45'),
      );
      when(() => appUser.gender).thenReturn(Gender.male);
      when(() => appUser.appVersion).thenReturn('1.0.0');
      when(() => appUser.createdAt).thenReturn(DateTime(2024, 1, 1));

      final container = await _prewarmedContainer(
        prefsRepo: prefsRepo,
        personalRepo: personalRepo,
        userRepo: userRepo,
        mockAuth: mockAuth,
        user: appUser,
      );

      // Pump widget
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(Duration(milliseconds: 500)); // Extra pump for async stability

      // Debug: Dump widget tree
      debugDumpApp();
      print('All text widgets: ${tester.widgetList(find.byType(Text)).map((w) => (w as Text).data).toList()}');

      // Debug: Verify appUser is not null
      final appUserState = container.read(authUserProvider).valueOrNull;
      expect(appUserState, isNotNull, reason: 'authUserProvider should provide a non-null user');

      // Find and interact with "Preferred venue types"
      final prefFinder = findTextLoose('Preferred venue types');
      print('Preferred venue types widgets: ${tester.widgetList(prefFinder).toList()}');
      expect(prefFinder, findsOneWidget, reason: 'Should find exactly one "Preferred venue types" widget');

      // Scroll to ensure visibility
      final listView = find.byType(ListView);
      await tester.scrollUntilVisible(prefFinder, 100.0, scrollable: listView);
      await tester.pumpAndSettle();

      await tester.tap(prefFinder);
      await tester.pumpAndSettle();

      // Tap Save in the dialog
      final saveButton = find.text('Save').last;
      expect(saveButton, findsOneWidget, reason: 'Should find Save button in dialog');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify repository call
      verify(() => prefsRepo.updatePreferredVenueTypes(
        uid: 'uid_123',
        types: any(named: 'types'),
      )).called(1);

      // Verify SharedPreferences
      final sp = await SharedPreferences.getInstance();
      final cached = sp.getStringList('pref_venue_types');
      expect(cached, isNotNull, reason: 'SharedPreferences should have saved venue types');
      expect(cached!.isNotEmpty, isTrue, reason: 'Saved venue types should not be empty');
    });

    testWidgets('Max venue distance -> repo + SharedPreferences', (tester) async {
      // Setup
      final prefsRepo = MockPreferencesRepository();
      final personalRepo = MockPersonalSettingsRepository();
      final userRepo = MockUserRepository();

      when(() => prefsRepo.updateMaxDistanceKm(
        uid: any(named: 'uid'),
        km: any(named: 'km'),
      )).thenAnswer((_) async {});

      final fbUser = MockUser(uid: 'uid_123');
      final mockAuth = MockFirebaseAuth(mockUser: fbUser, signedIn: true);

      final appUser = MockAppUser();
      when(() => appUser.homeCountryCode).thenReturn('DK');
      when(() => appUser.homeTown).thenReturn('copenhagen');
      when(() => appUser.homeLocationLocked).thenReturn(true);
      when(() => appUser.isVerified).thenReturn(false);
      when(() => appUser.roles).thenReturn(<UserRole>{UserRole.user});
      when(() => appUser.subscriptionType).thenReturn(SubscriptionTypesUser.free);
      when(() => appUser.preferredVenueTypes)
          .thenReturn(<VenueType>{VenueType.bar, VenueType.club, VenueType.pub});
      when(() => appUser.maxDistanceKm).thenReturn(50);
      when(() => appUser.email).thenReturn('me@example.com');
      when(() => appUser.userName).thenReturn('tester');
      when(() => appUser.firstName).thenReturn('Test');
      when(() => appUser.middleName).thenReturn('');
      when(() => appUser.lastName).thenReturn('User');
      when(() => appUser.displayFullName).thenReturn('Test User');
      when(() => appUser.birthDate).thenReturn(DateTime(1990, 1, 1));
      when(() => appUser.phoneNumber).thenReturn(
        phone.PhoneNumber.tryParse('+4512345678', iso2: 'DK', callingCode: '45'),
      );
      when(() => appUser.gender).thenReturn(Gender.male);
      when(() => appUser.appVersion).thenReturn('1.0.0');
      when(() => appUser.createdAt).thenReturn(DateTime(2024, 1, 1));

      final container = await _prewarmedContainer(
        prefsRepo: prefsRepo,
        personalRepo: personalRepo,
        userRepo: userRepo,
        mockAuth: mockAuth,
        user: appUser,
      );

      // Pump widget
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(Duration(milliseconds: 500)); // Extra pump for async stability

      // Debug: Dump widget tree
      debugDumpApp();
      print('All text widgets: ${tester.widgetList(find.byType(Text)).map((w) => (w as Text).data).toList()}');

      // Debug: Verify appUser is not null
      final appUserState = container.read(authUserProvider).valueOrNull;
      expect(appUserState, isNotNull, reason: 'authUserProvider should provide a non-null user');

      // Find and interact with "Max venue distance (km)"
      final maxFinder = findTextLoose('Max venue distance (km)');
      print('Max venue distance widgets: ${tester.widgetList(maxFinder).toList()}');
      expect(maxFinder, findsOneWidget, reason: 'Should find exactly one "Max venue distance (km)" widget');

      // Scroll to ensure visibility
      final listView = find.byType(ListView);
      await tester.scrollUntilVisible(maxFinder, 100.0, scrollable: listView);
      await tester.pumpAndSettle();

      await tester.tap(maxFinder);
      await tester.pumpAndSettle();

      // Enter new distance
      final tf = find.byType(TextField).last;
      expect(tf, findsOneWidget, reason: 'Should find TextField in dialog');
      await tester.enterText(tf, '100');
      await tester.pumpAndSettle();

      // Tap Save in the dialog
      final saveButton = find.text('Save').last;
      expect(saveButton, findsOneWidget, reason: 'Should find Save button in dialog');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify repository call
      verify(() => prefsRepo.updateMaxDistanceKm(
        uid: 'uid_123',
        km: 100.0,
      )).called(1);

      // Verify SharedPreferences
      final sp = await SharedPreferences.getInstance();
      expect(sp.getDouble('pref_max_distance_km'), 100.0, reason: 'SharedPreferences should have saved max distance');
    });
  });
}