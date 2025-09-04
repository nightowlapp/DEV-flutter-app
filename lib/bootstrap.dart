import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:nightowlcode/core/error_handler.dart';
import 'package:nightowlcode/data/repositories/users/auth/auth_repository.dart';
import 'package:nightowlcode/data/services/location/location_service.dart';
import 'package:nightowlcode/night_owl_app.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_screen.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nightowlcode/shared/utility/utility.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_config.dart';
import 'core/storage/app_storage.dart';
import 'core/storage/venues_sso.dart';
import 'data/app_lifecycle_observer.dart';
import 'data/other_providers.dart';
import 'data/providers/party_status/party_status_provider.dart';
import 'data/services/notifications/notification_service.dart';
import 'firebase_options.dart';

Future<void> _preBoot() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Firestore.instance.enablePersistence();
  await initLocalStores();

  // FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

  // ref.read(locationServiceProvider.notifier).initialize(context);
  TzUtils.ensureInitialized();

  const InitTasks(child: NightOwlApp(),);

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
  //   venues$: VenueRepository2.,
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
      //TODO? Above

      runApp(ProviderScope(
          // child: AppLifecycleObserver(
              overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
          ], child: builder()));
    // );
    }, (error, stack) {
      handleError(error, stack);
    }
  );
}

@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  // If you need Firebase here:
  // await Firebase.initializeApp();
  // Minimal: log/handle data; the system shows the notification when app is bg/terminated
  // print('BG message: ${message.messageId}, data: ${message.data}');
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
    Future.microtask(() {ref.read(partyStatusAutoResetProvider);}); // Resets partyStatus at 08:00 e/d

    // fire-and-forget: initialize google_sign_in v7 with proper IDs
    Future.microtask(() async {
      try { await ref.read(authRepositoryProvider).prewarmGoogle(); } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
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