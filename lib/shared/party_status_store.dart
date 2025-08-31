// lib/shared/data/party_status_store.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

import '../core/storage/app_storage.dart';

abstract class PartyStatusStore {
  Future<PartyStatusTypes?> loadStatus();
  Future<void> saveStatus(PartyStatusTypes value);
}

class SharedPrefsPartyStatusStore implements PartyStatusStore {
  SharedPrefsPartyStatusStore(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'user.currentPartyStatus';

  @override
  Future<PartyStatusTypes?> loadStatus() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return PartyStatusTypes.values.firstWhere((e) => e.name == raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveStatus(PartyStatusTypes value) async {
    await _prefs.setString(_key, value.name);
  }
}

final partyStatusStoreProvider = Provider<PartyStatusStore>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SharedPrefsPartyStatusStore(prefs);
});
