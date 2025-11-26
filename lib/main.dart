// lib/main.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bootstrap.dart';
import 'core/error_handler.dart';
import 'core/storage/app_storage.dart';
import 'night_owl_app.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    GoRouter.optionURLReflectsImperativeAPIs = true;
    GoogleFonts.config.allowRuntimeFetching = false;

    // ✅ Now this is really light: prefs + "stayLoggedIn" flag only
    final bootstrapResult = await preBootLight();

    final db = FirebaseFirestore.instance;
    db.settings = const Settings(persistenceEnabled: true);

    runApp(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(bootstrapResult.prefs),
        ],
        child: NightOwlRootApp(initial: bootstrapResult.dest),
      ),
    );
  }, (error, stack) {
    handleError(error, stack);
  });
}

class NightOwlRootApp extends StatelessWidget {
  const NightOwlRootApp({
    super.key,
    required this.initial,
  });

  final StartDest initial;

  @override
  Widget build(BuildContext context) {
    // Heavy boot (Firebase, Hive, env switch, Mapbox...) runs AFTER first frame
    return PostBootHost(
      child: NightOwlApp(initial: initial),
    );
  }
}
