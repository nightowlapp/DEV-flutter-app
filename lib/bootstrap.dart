import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:nightowlcode/core/error_handler.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_screen.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nightowlcode/shared/utility/utility.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_config.dart';
import 'core/storage/app_storage.dart';
import 'core/storage/venues_sso.dart';
import 'data/providers/geofence/geofencing_orchestrator_provider.dart';
import 'data/providers/party_status/party_status_provider.dart';
import 'data/services/notifications/notification_service.dart';
import 'dev_firebase_options.dart';
// import 'firebase_options.dart';

Future<void> _preBoot() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Firestore.instance.enablePersistence(); // What is this?

  // ref.read(locationServiceProvider.notifier).initialize(context); // TODO Sort out location first.

  // Fetch cache
  await initLocalStores();

  // Notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final notif = NotificationService();
  await notif.initLocalNotifications();
  await notif.init();

  //Timezone
  TzUtils.ensureInitialized();

  // Fetch/sort already in init to figure out friends, venues and so on? todo

  // Foreground presentation options (iOS)
  // await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  //   alert: true, badge: true, sound: true,
  // );
  // Init + subscribe to segments
  // final notificationService = NotificationService();
  // await notificationService.init();

  // TODO Figure out where to put and make work
  // venues$ can be your VenuesRepository.watchViewport(...) stream, or a broader subscription around user
  // final orchestrator = GeofencingOrchestrator(
  //   location$: LocationService.location$,
  //   venues$: VenueRepository.,
  //   presenceRepo: GeofencingRepository("currentUserId"),
  // );

  // ✅ Use AppConfig (has default + dart-define override)
  final cfg = AppConfig.current;
  final token = cfg.accessToken;

  // Basic validation to catch mistakes early
  if (token.isEmpty || !token.startsWith('pk.')) {
    // You can throw or log; throwing fails fast in dev.
    throw StateError(
      'Mapbox ACCESS_TOKEN is missing or invalid (must start with "pk.").',
    );
  }

  MapboxOptions.setAccessToken(token);
  SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

  // otherq

}

@pragma('vm:entry-point') // required by Android
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you show local notifications for data-only pushes, init plugins here.
  await Firebase.initializeApp();
  // print('BG push: ${message.messageId} data=${message.data}');
}

Future<void> initLocalStores() async {
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
}

void bootstrap(Widget Function() builder) {
  // Framework errors

  // FlutterError.onError = (details) {
  //   FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  //   logE('FlutterError', details.exception, details.stack);
  // };

  // Uncaught async errors (zone)
  runZonedGuarded(() async {
      // Engine-level errors (Dart 3+)
      PlatformDispatcher.instance.onError = (error, stack) {
        handleError(error, stack);
        return true; // tell engine we handled it
      };

      await _preBoot();
      // authStateChanges() TODO to stay signed in when login!.

      final prefs = await SharedPreferences.getInstance();
      runApp(ProviderScope(
          // child: AppLifecycleObserver(
          overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
          child: InitTasks(              // <-- MOUNT the initializer
            child: builder(),
          ),
        )
      );
      // );
    }, (error, stack) {
      handleError(error, stack);
    }
  );
}

class InitTasks extends ConsumerStatefulWidget {
  const InitTasks({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<InitTasks> createState() => _InitTasksState();
}

class _InitTasksState extends ConsumerState<InitTasks> {
  @override
  void initState() {
    super.initState();
    // database sync
    Future.microtask(() => ref.read(venuesSsoProvider.future));

    Future.microtask(() => ref.read(partyStatusBootstrapProvider.future));
    Future.microtask(() => ref.read(partyStatusAutoResetProvider)); // Resets partyStatus at 08:00 e/d

  }

  @override
  Widget build(BuildContext context) {
    ref.watch(geofencingOrchestratorProvider);
    return widget.child;
  }
}

class VenuesBoot extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venues = ref.watch(venuesSsoProvider);
    return venues.when(
      data: (list) => Scaffold(
        appBar: AppBar(title: const Text('Venues')),
        body: ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(list[i].displayName ?? list[i].name),
            subtitle: Text(list[i].id),
          ),
        ),
      ),
      loading: () => const Scaffold(body: Center(child: LoadingScreen())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }


}


