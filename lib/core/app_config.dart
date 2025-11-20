// lib/core/app_config.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Compile-time config via --dart-define.
/// Examples:
/// flutter run --dart-define=APP_ENV=dev
/// flutter run --dart-define=APP_ENV=prod
class AppConfig {
  final String env; // 'dev' or 'prod'
  final String appTitle;
  final String accessToken;
  final String googleServerClientId;
  final String googleIosClientId;

  const AppConfig({
    required this.env,
    required this.appTitle,
    required this.accessToken,
    required this.googleServerClientId,
    required this.googleIosClientId,
  });

  /// Single source of truth for env.
  static const String envName =
  String.fromEnvironment('APP_ENV', defaultValue: 'prod');
  // String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  bool get isProd => env == 'prod';
  bool get isDev => env == 'dev';

  static const AppConfig current = AppConfig(
    env: envName,
    appTitle: envName == 'prod' ? 'NightOwl' : '(Dev) NightOwl',
    accessToken: String.fromEnvironment(
      'MAPBOX_ACCESS_TOKEN',
      defaultValue:
      'pk.eyJ1IjoibmlnaHQtb3dsIiwiYSI6ImNtZnpmbmZsYTAxNnEya3M5eHJlcnlteGYifQ._IsVBAIAbKg7GZgJLdo7qA',
    ),
    googleServerClientId: String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue:
      '658302244013-nn1l5bnl7trst9hcvnmlrnj2da5b62nv.apps.googleusercontent.com',
    ),
    googleIosClientId: String.fromEnvironment(
      'GOOGLE_IOS_CLIENT_ID',
      // Google Sign-In for iOS (your ios OAuth client ID). Can be empty until you wire it.
      defaultValue: '',
    ),
  );
}

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
