import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

// class SharedPrefs SharedPreferences ((ref){ // TODO helper that has all set/get prefs using env when needed dev + prod should share last known location
//   final prefs = ref.watch(sharedPrefsProvider);
//   final lat = sharedPrefsFutureProvider.getDouble('last_lat');
//
// static String get _boxName => EnvStorage.hiveBoxName('venues_box');
//
// }

class EnvStorage {
  // 'dev' or 'prod'
  static String get env => AppConfig.envName;

  /// Hive box name: e.g. hiveBoxName('venues_box') -> 'venues_box_dev'
  static String hiveBoxName(String base) => '${base}_$env';

  /// SharedPreferences key: e.g. prefsKey('last_lat') -> 'dev_last_lat'
  static String prefsKey(String base) => '${env}_$base';

//   static String mapboxStyle{ //TODO
//
//     if(AppConfig.current.env = AppConfig.current.isProd){
//       return 'mapbox://styles/night-owl/cmfzfrida004u01s5co906aj5';
//   }else
//     return 'mapbox://styles/night-owl/cmi6bl6jd00as01secypxenk8'
// }
}
