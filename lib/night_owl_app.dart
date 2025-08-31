import 'package:flutter/material.dart';
import 'package:nightowlcode/core/app_config.dart';
import 'package:nightowlcode/core/error_handler.dart';
import 'package:nightowlcode/core/theme.dart';

import 'navigation/router.dart';

class NightOwlApp extends StatelessWidget {
  const NightOwlApp({super.key});

  @override
  Widget build(BuildContext context) { // TODO look into setting up start correct.
    final config = AppConfig.current;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: config.appTitle,
      routerConfig: router,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme().defaultAppTheme,


// navigatorKey:

      // locale: const Locale('en'),
      // supportedLocales: const [Locale('en')],


      // localizationsDelegates: const [
        // GlobalMaterialLocalizations.delegate,
        // GlobalWidgetsLocalizations.delegate,
        // GlobalCupertinoLocalizations.delegate,
      // ],
    );
  }
}

