import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import 'package:nightowlcode/shared/constants/enums.dart';
import '../data/repositories/users/party_status_repository.dart';

/// Computes a day-key with an 08:00 boundary.
String partyStatusDayKey(DateTime now) {
  final d = now.subtract(const Duration(hours: 8));
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
      // Do NOT touch kPartyStatusAnsweredDayKey here.
      return PartyStatusTypes.still_planning;
    }

    try {
      return PartyStatusTypes.values.firstWhere((e) => e.name == stored);
    } catch (_) {}
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

    // Mark answered ONLY for manual (user-driven) changes.
    if (change == PartyStatusChange.manual) {
      await _prefs.setString(kPartyStatusAnsweredDayKey, currentDay);
    }
  }
}

/* ---------- Firestore-backed ---------- */
class FirestorePartyStatusStore implements PartyStatusStore {
  FirestorePartyStatusStore(this.repo, this.local);
  final PartyStatusRepository repo;
  final SharedPrefsPartyStatusStore local;

  @override
  Future<PartyStatusTypes?> loadStatus() async {
    final now = DateTime.now();
    final storedDay = local._prefs.getString(SharedPrefsPartyStatusStore._kDay);
    final currentDay = partyStatusDayKey(now);
    final needsReset = storedDay != null && storedDay != currentDay;

    if (needsReset) {
      await saveStatus(
        PartyStatusTypes.still_planning,
        change: PartyStatusChange.automatic,
        writeToCloud: false,
      );
      return PartyStatusTypes.still_planning;
    }

    final status = await local.loadStatus() ?? PartyStatusTypes.still_planning;
    return status;
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
      await repo.recordStatus(
        status: value,
        change: change,
        position: position,
        now: DateTime.now(),
      );
    }
  }
}
