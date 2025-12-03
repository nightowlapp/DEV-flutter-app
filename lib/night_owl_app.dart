// lib/night_owl_app.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/core/app_config.dart';
import 'package:nightowlcode/core/theme.dart';

import 'bootstrap.dart'; // for StartDest
import 'core/error_handler.dart';
import 'navigation/router.dart';

// lib/night_owl_app.dart
class NightOwlApp extends StatelessWidget {
  const NightOwlApp({
    super.key,
    this.initial = StartDest.login,
  });

  final StartDest initial;

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.current;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: config.appTitle,
      theme: AppTheme().defaultAppTheme,
      routerConfig: createRouter(
        initialLocation:
            initial == StartDest.explore ? '/explore' : '/login-or-create',
      ),
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}
