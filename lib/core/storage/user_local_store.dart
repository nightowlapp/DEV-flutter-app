// lib/storage/user_local_store.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nightowlcode/models/users/user.dart' as model;

class MeLocalStore {
  MeLocalStore(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'me_cache_v1'; // bump if schema changes

  Future<model.User?> read() async {
    final s = _prefs.getString(_key);
    if (s == null || s.isEmpty) return null;
    try {
      final map = json.decode(s) as Map<String, dynamic>;
      return model.User.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(model.User u) async {
    await _prefs.setString(_key, json.encode(u.toJson()..['id'] = u.id));
  }

  Future<void> clear() async => _prefs.remove(_key);
}
