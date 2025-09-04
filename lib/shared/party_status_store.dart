// lib/shared/party_status_store.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:geolocator/geolocator.dart';

import '../data/repositories/users/party_status_repository.dart';

/// Public so other files can compute the same “day key”.
String partyStatusDayKey(DateTime now) {
  final d = now.subtract(const Duration(hours: 8)); // 08:00 boundary
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Public so providers don’t duplicate the string.
const kPartyStatusAnsweredDayKey = 'user.currentPartyStatus.answeredDayKey';

abstract class PartyStatusStore {
  Future<PartyStatusTypes?> loadStatus();
  Future<void> saveStatus(
      PartyStatusTypes value, {
        PartyStatusChange change = PartyStatusChange.manual,
        Position? position,
        bool writeToCloud = true,
      });
}

/* ---------- Local ---------- */

class SharedPrefsPartyStatusStore implements PartyStatusStore {
  SharedPrefsPartyStatusStore(this._prefs);
  final SharedPreferences _prefs;

  static const _kVal = 'user.currentPartyStatus';
  static const _kDay = 'user.currentPartyStatus.dayKey';

  @override
  Future<PartyStatusTypes?> loadStatus() async {
    final stored = _prefs.getString(_kVal);
    final storedDay = _prefs.getString(_kDay);
    if (stored == null) return null;

    final currentDay = partyStatusDayKey(DateTime.now());

    // Crossed 08:00 boundary since last write → auto reset.
    if (storedDay != currentDay) {
      await _prefs.setString(_kVal, PartyStatusTypes.still_planning.name);
      await _prefs.setString(_kDay, currentDay);
      // NOTE: do NOT touch kPartyStatusAnsweredDayKey here.
      return PartyStatusTypes.still_planning;
    }

    try {
      return PartyStatusTypes.values.firstWhere((e) => e.name == stored);
    } catch (_) {
      return PartyStatusTypes.still_planning;
    }
  }

  @override
  Future<void> saveStatus(
      PartyStatusTypes value, {
        PartyStatusChange change = PartyStatusChange.manual,
        Position? position,
        bool writeToCloud = true,
      }) async {
    final currentDay = partyStatusDayKey(DateTime.now());
    await _prefs.setString(_kVal, value.name);
    await _prefs.setString(_kDay, currentDay);

    // Mark “answered today” only when user picked something manually.
    if (change == PartyStatusChange.manual || change == PartyStatusChange.values) { //Any change.
      await _prefs.setString(kPartyStatusAnsweredDayKey, currentDay);
    }
  }
}

/* ---------- Firestore-backed (unchanged except calling recordStatus) ---------- */

class FirestorePartyStatusStore implements PartyStatusStore {
  FirestorePartyStatusStore(this.repo, this.local);
  final PartyStatusRepository repo;
  final SharedPrefsPartyStatusStore local;

  @override
  Future<PartyStatusTypes?> loadStatus() async {
    final cached = await local.loadStatus();
    try {
      final cloud = await repo.loadCurrentStatus();
      if (cloud != null) await local.saveStatus(cloud);
      return cloud ?? cached;
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<void> saveStatus(
      PartyStatusTypes value, {
        PartyStatusChange change = PartyStatusChange.manual,
        Position? position,
        bool writeToCloud = true,
      }) async {
    await local.saveStatus(value, change: change);
    if (writeToCloud) {
      // ignore: unawaited_futures
      repo.recordStatus(
        status: value, change: change, position: position, now: DateTime.now(),
      );
    }
  }
}
