import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Compile-time config via --dart-define.
/// Examples:
/// flutter run --dart-define=APP_ENV=dev
/// flutter run --dart-define=APP_ENV=prod --dart-define=USE_EMULATORS=true
class AppConfig {
  final String env;
  final String appTitle;
  final String accessToken;
  final String googleServerClientId;
  final String googleIosClientId;

  const AppConfig({
    this.env = 'dev',
    this.appTitle = 'NightOwl',
    required this.accessToken,
    required this.googleServerClientId,
    required this.googleIosClientId,
  });

  bool get isProd => env == 'prod';
  bool get isDev => env == 'dev';

  static AppConfig get current => const AppConfig(
        accessToken: String.fromEnvironment('MAPBOX_ACCESS_TOKEN',
            // defaultValue: 'pk.eyJ1IjoibmlnaHR2aWV3IiwiYSI6ImNtYjBwdmhkaTB3aTkyaXEycmY3dXQ5czUifQ.XFwAjV4tzjFwKh2h1JmKoQ'), // test
            defaultValue:
                'pk.eyJ1IjoibmlnaHQtb3dsIiwiYSI6ImNtZnpmbmZsYTAxNnEya3M5eHJlcnlteGYifQ._IsVBAIAbKg7GZgJLdo7qA'),
        googleServerClientId: String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID',
            defaultValue:
                '658302244013-nn1l5bnl7trst9hcvnmlrnj2da5b62nv.apps.googleusercontent.com'),
        googleIosClientId:
            String.fromEnvironment('GOOGLE_IOS_CLIENT_ID', defaultValue: ''),
      );
}

// static const String AppVersion = '0.1.0';

class AppVersionInfo {
  final String version; // e.g. 0.1.0
  final String build; // e.g. 12
  const AppVersionInfo(this.version, this.build);
  String get label => '$version+$build';
}

final appVersionProvider = FutureProvider<AppVersionInfo>((ref) async {
  final p = await PackageInfo.fromPlatform();
  return AppVersionInfo(p.version, p.buildNumber);
});
