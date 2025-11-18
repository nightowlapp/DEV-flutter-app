import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:nightowlcode/core/error_handler.dart';
import 'package:nightowlcode/core/platform_config.dart';
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
  await _resetIfFirebaseProjectChanged();

  // ref.read(locationServiceProvider.notifier).initialize(context); // TODO Sort out location first.

  await initLocalStores();

  // Notifications
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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



Future<FirebaseApp> ensureFirebaseInitialized() async {
  // If the default app already exists (native auto-init or hot-restart), just use it.
  try {
    return Firebase.app();
  } on FirebaseException catch (e) {
    if (e.code != 'no-app') rethrow; // unexpected error
  }

  // Otherwise, create it once.
  try {
    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    // If a race (or native provider) created it between the check & init,
    // use the existing one.
    if (e.code == 'duplicate-app') {
      return Firebase.app();
    }
    rethrow;
  }
}

@pragma('vm:entry-point') // required by Android
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you show local notifications for data-only pushes, init plugins here.
  // await Firebase.initializeApp();
  // print('BG push: ${message.messageId} data=${message.data}');
}

Future<void> initLocalStores() async {
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
}

void bootstrap(Widget Function() builder) {
  // Framework errors TODO

  // FlutterError.onError = (details) {
  //   FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  //   logE('FlutterError', details.exception, details.stack);
  // };


  runZonedGuarded(() {
    runApp(_BootGate(builder: builder));
  }, (error, stack) {
    handleError(error, stack);
  });
}

class _BootGate extends StatefulWidget {
  const _BootGate({required this.builder});
  final Widget Function() builder;

  @override
  State<_BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<_BootGate> {
  bool _ready = false;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    // Let the first frame paint, then start heavy init
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    try {
      await _preBoot(); // your existing init: Firebase guard, resets, notif, etc.
      _prefs = await SharedPreferences.getInstance();
    } catch (e, s) {
      handleError(e, s);
    } finally {
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      // Show YOUR LoadingScreen immediately
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoadingScreen(),
      );
    }

    // When ready, boot the real app with your existing overrides
    return ProviderScope(
      overrides: [
        if (_prefs != null) sharedPrefsProvider.overrideWithValue(_prefs!),
      ],
      child: InitTasks(child: widget.builder()),
    );
  }
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
    if(PlatformConfig.isIOS){
     Future.microtask(() {
      ref.read(trackingInitProvider.future);
    });
    }

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

const _kProjectIdPrefsKey = 'last_firebase_project_id';

Future<void> _resetNonFirebaseLocalState() async {
  // 1) Local notifications
  try {
    final fln = FlutterLocalNotificationsPlugin();
    await fln.cancelAll();
  } catch (_) {}

  // 2) SharedPreferences
  try {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  } catch (_) {}

  // 3) Hive (close + delete its directory)
  try {
    await Hive.close();
  } catch (_) {}
  try {
    final docs = await getApplicationDocumentsDirectory();
    // Caution: this nukes your app docs (incl. Hive boxes)
    if (await docs.exists()) {
      await docs.delete(recursive: true);
    }
  } catch (_) {}

  // 4) Temp/cache files
  try {
    final tmp = await getTemporaryDirectory();
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  } catch (_) {}
}

Future<void> _resetFirebaseState() async {
  // Only after the app is initialized (ensureFirebaseInitialized was called)
  try {
    // Firestore cache
    await FirebaseFirestore.instance.terminate();
    await FirebaseFirestore.instance.clearPersistence();
  } catch (_) {}

  try {
    // Auth session
    await FirebaseAuth.instance.signOut();
  } catch (_) {}

  try {
    // Messaging token (forces a new token next run)
    await FirebaseMessaging.instance.deleteToken();
  } catch (_) {}

  // If you also use flutter_secure_storage or similar, delete there too.
  // (Not included here to avoid adding a new dependency.)
}

/// Call this early in _preBoot(): it detects project change and wipes state.
Future<void> _resetIfFirebaseProjectChanged() async {
  final prefs = await SharedPreferences.getInstance();
  final currentProjectId = DefaultFirebaseOptions.currentPlatform.projectId;
  final lastProjectId = prefs.getString(_kProjectIdPrefsKey);

  final changed = lastProjectId != null && lastProjectId != currentProjectId;

  if (changed) {
    // Phase 1: wipe non-Firebase local state (no Firebase needed)
    await _resetNonFirebaseLocalState();
  }

  // Make sure Firebase is up so we can reset its pieces
  await ensureFirebaseInitialized();

  if (changed) {
    // Phase 2: wipe Firebase bits now that core is ready
    await _resetFirebaseState();
  }

  // Record the project we’re now on
  await prefs.setString(_kProjectIdPrefsKey, currentProjectId);
}
