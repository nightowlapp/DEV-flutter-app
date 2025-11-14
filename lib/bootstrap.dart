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
import 'package:nightowlcode/core/tracking_consent.dart';
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
import 'data/providers/users/user_providers.dart';
import 'data/services/location/location_providers.dart';
import 'data/services/notifications/notification_service.dart';
// import 'dev_firebase_options.dart';
import 'firebase_options.dart';

Future<void> _preBoot() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ref.read(locationServiceProvider.notifier).initialize(context); // TODO Sort out location first.

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

  final cfg = AppConfig.current;
  MapboxOptions.setAccessToken(cfg.accessToken);

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

    final prefs = await SharedPreferences.getInstance();
    runApp(ProviderScope(
      // child: AppLifecycleObserver(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: InitTasks(
        // <-- MOUNT the initializer
        child: builder(),
      ),
    ));
    // );
  }, (error, stack) {
    handleError(error, stack);
  });
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
    Future.microtask(() => ref.read(meSsoProvider));

    Future.microtask(() {
      ref.read(venuesSsoProvider); // starts build; no await
    });
     Future.microtask(() {
      ref.read(trackingInitProvider.future);
    });

    // Other background boot tasks (non-blocking):
    Future.microtask(() => ref.read(partyStatusBootstrapProvider.future));
    Future.microtask(() => ref.read(partyStatusAutoResetProvider));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(geofencingOrchestratorProvider);
    ref.listen(latLngSafeStreamProvider, (prev, next) {
      final p = next.maybeWhen(data: (v) => v, orElse: () => null);
      if (p != null) {
        final prefs = ref.read(sharedPrefsProvider);
        prefs.setDouble('last_lat', p.lat);
        prefs.setDouble('last_lng', p.lng);
      }
    });
    return widget.child;
  }
}

