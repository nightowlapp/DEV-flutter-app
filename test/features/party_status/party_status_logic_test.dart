// import 'package:clock/clock.dart';
// import 'package:fake_async/fake_async.dart';
// import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:nightowlcode/core/storage/app_storage.dart';
// import 'package:nightowlcode/data/other_providers.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'package:nightowlcode/data/providers/party_status/party_status_provider.dart';
// import 'package:nightowlcode/data/repositories/users/party_status_repository.dart';
// import 'package:nightowlcode/shared/constants/enums.dart';
// import 'package:nightowlcode/shared/party_status_store.dart';
//
// void main() {
//   TestWidgetsFlutterBinding.ensureInitialized();
//
//   group('Party Status Feature', () {
//     setUp(() async {
//       SharedPreferences.setMockInitialValues({});
//     });
//
//     test('Manual set saves to local and DB, updates display, needsAnswer=false', () async {
//       final mockAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'test_uid'));
//       final mockFirestore = FakeCloudFirestore();
//       final prefs = await SharedPreferences.getInstance();
//
//       final container = ProviderContainer(overrides: [
//         firebaseAuthProvider.overrideWithValue(mockAuth),
//         firestoreProvider.overrideWithValue(mockFirestore),
//         sharedPrefsProvider.overrideWithValue(prefs),
//       ]);
//       addTearDown(container.dispose);
//
//       await container.read(partyStatusBootstrapProvider.future);
//       expect(container.read(partyStatusStateProvider), PartyStatusTypes.still_planning);
//       expect(container.read(partyStatusNeedsAnswerProvider), true);
//
//       final store = container.read(partyStatusStoreProvider);
//       await store.saveStatus(
//         PartyStatusTypes.house_party,
//         change: PartyStatusChange.manual,
//         position: Position(
//           longitude: 0,
//           latitude: 0,
//           timestamp: DateTime.now(),
//           accuracy: 0,
//           altitude: 0,
//           altitudeAccuracy: 0,
//           heading: 0,
//           headingAccuracy: 0,
//           speed: 0,
//           speedAccuracy: 0,
//         ),
//       );
//       container.read(partyStatusStateProvider.notifier).state = PartyStatusTypes.house_party;
//
//       expect(container.read(partyStatusStateProvider), PartyStatusTypes.house_party);
//       expect(container.read(partyStatusNeedsAnswerProvider), false);
//       expect(await store.loadStatus(), PartyStatusTypes.house_party);
//
//       final userDoc = await mockFirestore.collection('users').doc('test_uid').get();
//       expect(userDoc.data()?['current_party_status'], 'house_party');
//
//       final day = PartyStatusRepository(mockFirestore, mockAuth).dayId(DateTime.now());
//       final entriesCol = mockFirestore
//           .collection('users')
//           .doc('test_uid')
//           .collection('party_status_days')
//           .doc(day)
//           .collection('entries');
//       final entries = await entriesCol.get();
//       expect(entries.docs.isNotEmpty, true);
//       expect(entries.docs.first.data()['party_status'], 'house_party');
//       expect(entries.docs.first.data()['change'], 'manual');
//     });
//
//     test('Auto reset at 08:00 via timer, updates local/DB/display, needsAnswer=true', () {
//       fakeAsync((async) {
//         DateTime currentTime = DateTime(2025, 9, 6, 7, 0); // Before 08:00
//         final clock = Clock(() => currentTime);
//
//         withClock(clock, () async {
//           final mockAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'test_uid'));
//           final mockFirestore = FakeCloudFirestore();
//           final prefs = await SharedPreferences.getInstance();
//
//           final container = ProviderContainer(overrides: [
//             firebaseAuthProvider.overrideWithValue(mockAuth),
//             firestoreProvider.overrideWithValue(mockFirestore),
//             sharedPrefsProvider.overrideWithValue(prefs),
//           ]);
//           addTearDown(container.dispose);
//
//           await container.read(partyStatusBootstrapProvider.future);
//           container.read(partyStatusAutoResetProvider); // Sets up timer for 08:00 (1 hour from now)
//
//           final store = container.read(partyStatusStoreProvider);
//           await store.saveStatus(
//             PartyStatusTypes.house_party,
//             change: PartyStatusChange.manual,
//             position: Position(
//               longitude: 0,
//               latitude: 0,
//               timestamp: currentTime,
//               accuracy: 0,
//               altitude: 0,
//               altitudeAccuracy: 0,
//               heading: 0,
//               headingAccuracy: 0,
//               speed: 0,
//               speedAccuracy: 0,
//             ),
//           );
//           container.read(partyStatusStateProvider.notifier).state = PartyStatusTypes.house_party;
//
//           expect(container.read(partyStatusStateProvider), PartyStatusTypes.house_party);
//           expect(container.read(partyStatusNeedsAnswerProvider), false);
//
//           // Advance time past 08:00
//           currentTime = currentTime.add(const Duration(hours: 2)); // Now 09:00
//           async.elapse(const Duration(hours: 2));
//
//           expect(container.read(partyStatusStateProvider), PartyStatusTypes.still_planning);
//           expect(container.read(partyStatusNeedsAnswerProvider), true);
//           expect(await store.loadStatus(), PartyStatusTypes.still_planning);
//
//           final userDoc = await mockFirestore.collection('users').doc('test_uid').get();
//           expect(userDoc.data()?['current_party_status'], 'still_planning');
//
//           final day = PartyStatusRepository(mockFirestore, mockAuth).dayId(currentTime);
//           final entriesCol = mockFirestore
//               .collection('users')
//               .doc('test_uid')
//               .collection('party_status_days')
//               .doc(day)
//               .collection('entries');
//           final entries = await entriesCol.get();
//           final resetEntry = entries.docs.last.data();
//           expect(resetEntry['party_status'], 'still_planning');
//           expect(resetEntry['change'], 'automatic');
//         });
//       });
//     });
//
//     test('Cold open after 08:00 resets local/DB/display on load, needsAnswer=true', () async {
//       final mockAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'test_uid'));
//       final mockFirestore = FakeCloudFirestore();
//       final prefs = await SharedPreferences.getInstance();
//
//       // Simulate previous day set (before reset)
//       DateTime prevTime = DateTime(2025, 9, 6, 7, 0);
//       final clockPrev = Clock(() => prevTime);
//       withClock(clockPrev, () async {
//         final containerPrev = ProviderContainer(overrides: [
//           firebaseAuthProvider.overrideWithValue(mockAuth),
//           firestoreProvider.overrideWithValue(mockFirestore),
//           sharedPrefsProvider.overrideWithValue(prefs),
//         ]);
//
//         await containerPrev.read(partyStatusBootstrapProvider.future);
//         final storePrev = containerPrev.read(partyStatusStoreProvider);
//         await storePrev.saveStatus(
//           PartyStatusTypes.house_party,
//           change: PartyStatusChange.manual,
//           position: Position(
//             longitude: 0,
//             latitude: 0,
//             timestamp: prevTime,
//             accuracy: 0,
//             altitude: 0,
//             altitudeAccuracy: 0,
//             heading: 0,
//             headingAccuracy: 0,
//             speed: 0,
//             speedAccuracy: 0,
//           ),
//         );
//         containerPrev.read(partyStatusStateProvider.notifier).state = PartyStatusTypes.house_party;
//         expect(containerPrev.read(partyStatusNeedsAnswerProvider), false);
//
//         containerPrev.dispose();
//       });
//
//       // New session after reset time
//       DateTime newTime = DateTime(2025, 9, 6, 9, 0);
//       final clockNew = Clock(() => newTime);
//       withClock(clockNew, () async {
//         final containerNew = ProviderContainer(overrides: [
//           firebaseAuthProvider.overrideWithValue(mockAuth),
//           firestoreProvider.overrideWithValue(mockFirestore),
//           sharedPrefsProvider.overrideWithValue(prefs),
//         ]);
//         addTearDown(containerNew.dispose);
//
//         await containerNew.read(partyStatusBootstrapProvider.future);
//
//         expect(containerNew.read(partyStatusStateProvider), PartyStatusTypes.still_planning);
//         expect(containerNew.read(partyStatusNeedsAnswerProvider), true);
//
//         final userDoc = await mockFirestore.collection('users').doc('test_uid').get();
//         expect(userDoc.data()?['current_party_status'], 'still_planning');
//
//         final day = PartyStatusRepository(mockFirestore, mockAuth).dayId(newTime);
//         final entriesCol = mockFirestore
//             .collection('users')
//             .doc('test_uid')
//             .collection('party_status_days')
//             .doc(day)
//             .collection('entries');
//         final entries = await entriesCol.get();
//         final resetEntry = entries.docs.last.data();
//         expect(resetEntry['party_status'], 'still_planning');
//         expect(resetEntry['change'], 'automatic');
//       });
//     });
//
//     test('Status persists before reset time, resets only after', () async {
//       final mockAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'test_uid'));
//       final mockFirestore = FakeCloudFirestore();
//       final prefs = await SharedPreferences.getInstance();
//
//       DateTime initialTime = DateTime(2025, 9, 6, 7, 0);
//       final clock = Clock(() => initialTime);
//       withClock(clock, () async {
//         final container = ProviderContainer(overrides: [
//           firebaseAuthProvider.overrideWithValue(mockAuth),
//           firestoreProvider.overrideWithValue(mockFirestore),
//           sharedPrefsProvider.overrideWithValue(prefs),
//         ]);
//         addTearDown(container.dispose);
//
//         await container.read(partyStatusBootstrapProvider.future);
//         final store = container.read(partyStatusStoreProvider);
//         await store.saveStatus(
//           PartyStatusTypes.house_party,
//           change: PartyStatusChange.manual,
//           position: Position(
//             longitude: 0,
//             latitude: 0,
//             timestamp: initialTime,
//             accuracy: 0,
//             altitude: 0,
//             altitudeAccuracy: 0,
//             heading: 0,
//             headingAccuracy: 0,
//             speed: 0,
//             speedAccuracy: 0,
//           ),
//         );
//         container.read(partyStatusStateProvider.notifier).state = PartyStatusTypes.house_party;
//
//         // Check before reset
//         final userDocBefore = await mockFirestore.collection('users').doc('test_uid').get();
//         expect(userDocBefore.data()?['current_party_status'], 'house_party');
//
//         // Simulate reload before reset (same time)
//         expect(await store.loadStatus(), PartyStatusTypes.house_party);
//       });
//
//       // After reset in new clock
//       DateTime afterTime = DateTime(2025, 9, 7, 9, 0); // Next day after 08:00
//       final clockAfter = Clock(() => afterTime);
//       withClock(clockAfter, () async {
//         final containerAfter = ProviderContainer(overrides: [
//           firebaseAuthProvider.overrideWithValue(mockAuth),
//           firestoreProvider.overrideWithValue(mockFirestore),
//           sharedPrefsProvider.overrideWithValue(prefs),
//         ]);
//         addTearDown(containerAfter.dispose);
//
//         await containerAfter.read(partyStatusBootstrapProvider.future);
//
//         expect(containerAfter.read(partyStatusStateProvider), PartyStatusTypes.still_planning);
//
//         final userDocAfter = await mockFirestore.collection('users').doc('test_uid').get();
//         expect(userDocAfter.data()?['current_party_status'], 'still_planning');
//       });
//     });
//   });
// }