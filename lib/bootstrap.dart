// lib/bootstrap.dart
import 'dart:async';
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
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nightowlcode/core/app_config.dart';
import 'package:nightowlcode/core/error_handler.dart';
import 'package:nightowlcode/core/logger.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/core/tracking_consent.dart';
import 'package:nightowlcode/core/storage/app_storage.dart';
import 'package:nightowlcode/core/storage/venues_sso.dart';
import 'package:nightowlcode/data/providers/geofence/geofencing_orchestrator_provider.dart';
import 'package:nightowlcode/data/providers/party_status/party_status_provider.dart';
import 'package:nightowlcode/data/providers/users/user_providers.dart';
import 'package:nightowlcode/data/services/location/location_providers.dart';
// import 'package:nightowlcode/data/services/notifications/notification_service.dart';
import 'package:nightowlcode/shared/utility/utility.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// IMPORTANT: dev/prod Firebase options must exist.
import 'firebase_options.dart' as prod;
import 'dev_firebase_options.dart' as dev;

/// Where the app is allowed to start.
enum StartDest { login, explore }

/// Value returned by pre-boot.
typedef BootstrapResult = ({SharedPreferences prefs, StartDest dest});

/// --------------------- LIGHT INIT (before runApp) ----------------------------

Future<BootstrapResult> preBootLight() async {
  // main() will call WidgetsFlutterBinding.ensureInitialized()

  GoogleFonts.config.allowRuntimeFetching = false;

  logI('(${AppConfig.envName}) NightOwl bootstrap start');

  // Detect env/project change, wipe caches if needed, and ensure Firebase
  await _resetIfEnvOrProjectChanged();

  // Hive base dir
  await _initHive();

  final prefs = await SharedPreferences.getInstance();
  final stay = prefs.getBool('stayLoggedIn') ?? true;

  // Firebase is already ensured by _resetIfEnvOrProjectChanged
  final user = FirebaseAuth.instance.currentUser;
  final dest = (user != null && stay) ? StartDest.explore : StartDest.login;

  // Mapbox
  final cfg = AppConfig.current;
  MapboxOptions.setAccessToken(cfg.accessToken);

  // Orientation
  await SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );

  logI('NightOwl bootstrap done → dest=$dest');

  return (prefs: prefs, dest: dest);
}

Future<void> _initHive() async {
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
}

/// Pick Firebase options based on APP_ENV.
FirebaseOptions _firebaseOptionsForEnv() {
  return prod.DefaultFirebaseOptions.currentPlatform;
  // const env = AppConfig.envName;
  // return env == 'prod'
  //     ? prod.DefaultFirebaseOptions.currentPlatform
  //     : dev.DefaultFirebaseOptions.currentPlatform;
}

String _firebaseProjectIdForEnv() {
  return _firebaseOptionsForEnv().projectId;
}

Future<FirebaseApp> ensureFirebaseInitialized() async {
  try {
    return Firebase.app();
  } on FirebaseException catch (e) {
    if (e.code != 'no-app') rethrow;
  }

  final options = _firebaseOptionsForEnv();
  logI(
    'Initializing Firebase for env=${AppConfig.envName}, '
    'projectId=${options.projectId}',
  );

  try {
    return await Firebase.initializeApp(
      options: options,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') return Firebase.app();
    rethrow;
  }
}

const _kProjectIdPrefsKey = 'last_firebase_project_id';
const _kEnvPrefsKey = 'last_app_env';

Future<void> _resetNonFirebaseLocalState() async {
  try {
    await FlutterLocalNotificationsPlugin().cancelAll();
  } catch (_) {}

  try {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  } catch (_) {}

  try {
    await Hive.close();
  } catch (_) {}

  try {
    final docs = await getApplicationDocumentsDirectory();
    if (await docs.exists()) {
      await docs.delete(recursive: true);
    }
  } catch (_) {}

  try {
    final tmp = await getTemporaryDirectory();
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  } catch (_) {}
}

Future<void> _resetFirebaseState() async {
  try {
    await FirebaseFirestore.instance.terminate();
    await FirebaseFirestore.instance.clearPersistence();
  } catch (_) {}

  try {
    await FirebaseAuth.instance.signOut();
  } catch (_) {}

  try {
    await FirebaseMessaging.instance.deleteToken();
  } catch (_) {}
}

/// Detect ENV / Firebase project switch (dev ↔ prod) and wipe caches once.
Future<void> _resetIfEnvOrProjectChanged() async {
  final prefs = await SharedPreferences.getInstance();

  final currentEnv = AppConfig.envName;
  final currentProjectId = _firebaseProjectIdForEnv();

  final lastEnv = prefs.getString(_kEnvPrefsKey);
  final lastProjectId = prefs.getString(_kProjectIdPrefsKey);

  // Treat null→value as "changed" as well so first run of new env wipes old data.
  final envChanged = lastEnv != currentEnv;
  final projectChanged = lastProjectId != currentProjectId;
  final changed = envChanged || projectChanged;

  logI(
    'Boot env=$currentEnv (lastEnv=$lastEnv, envChanged=$envChanged), '
    'projectId=$currentProjectId (lastProjectId=$lastProjectId, projectChanged=$projectChanged)',
  );

  if (changed) {
    logW('Env or Firebase project changed → wiping local state');
    await _resetNonFirebaseLocalState();
  }

  // Always make sure Firebase is usable after potential wipe
  await ensureFirebaseInitialized();

  if (changed) {
    await _resetFirebaseState();
  }

  await prefs.setString(_kEnvPrefsKey, currentEnv);
  await prefs.setString(_kProjectIdPrefsKey, currentProjectId);
}

/// -------------------- HEAVY INIT (after first frame) -------------------------

class PostBoot {
  static Future<void> run(WidgetRef ref) async {
    // Fire and forget; do NOT block UI thread.
    unawaited(_initNotifications());
    unawaited(_initTimeZones());

    // Kick providers (don’t await)
    unawaited(Future.microtask(() => ref.read(meSsoProvider)));
    unawaited(Future.microtask(() => ref.read(venuesSsoProvider)));
    if (PlatformConfig.isIOS) {
      unawaited(Future.microtask(() => ref.read(trackingInitProvider.future)));
    }
    unawaited(
      Future.microtask(() => ref.read(partyStatusBootstrapProvider.future)),
    );
    unawaited(
      Future.microtask(() => ref.read(partyStatusAutoResetProvider)),
    );
    unawaited(
      Future.microtask(() => ref.read(geofencingOrchestratorProvider)),
    );
    unawaited(
      Future.microtask(() => ref.read(locationServiceProvider)),
    );
  }

  static Future<void> _initNotifications() async {
    // final notif = NotificationService();
    // await notif.initLocalNotifications();
    // await notif.init();
  }

  static Future<void> _initTimeZones() async {
    try {
      TzUtils.ensureInitialized();
    } catch (_) {}
  }
}

/// Kicks heavy init right after the app is mounted.
class PostBootHost extends ConsumerStatefulWidget {
  const PostBootHost({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<PostBootHost> createState() => _PostBootHostState();
}

class _PostBootHostState extends ConsumerState<PostBootHost> {
  bool _kicked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_kicked) return;
    _kicked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PostBoot.run(ref);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
