// lib/data/services/location/live_location_sharing_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/providers/other_providers.dart';
import 'package:nightowlcode/models/users/location_audience.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'live_location_publisher.dart';

const _prefsKeyAudience = 'share_location_audience';
const _prefsKeyAudienceUpdatedAt = 'share_location_audience_updated_at';
const _resetHour = 8; // 08:00 local time

/// Singleton LiveLocationPublisher, auto-stopped when provider is disposed.
final liveLocationPublisherProvider = Provider<LiveLocationPublisher>((ref) {
  final pub = LiveLocationPublisher();
  ref.onDispose(() => pub.stop());
  return pub;
});

/// Current sharing audience (friends / closeFriends / none).
/// This also starts/stops the LiveLocationPublisher.
final shareAudienceProvider =
StateNotifierProvider<ShareAudienceController, LocationAudience>((ref) {
  final pub = ref.read(liveLocationPublisherProvider);
  final controller = ShareAudienceController(pub);

  // 🔁 Restore last choice (with 08:00 cutoff) & schedule reset.
  // fire-and-forget is fine here
  controller.restoreFromDisk();

  // If user logs out, stop sharing + reset.
  ref.listen(firebaseAuthProvider, (prev, next) {
    if (next.currentUser == null) {
      controller.setAudience(LocationAudience.none);
    }
  });

  return controller;
});


class ShareAudienceController extends StateNotifier<LocationAudience> {
  ShareAudienceController(this._publisher) : super(LocationAudience.none);

  final LiveLocationPublisher _publisher;
  Timer? _resetTimer;

  // ---------- init / restore ----------

  Future<void> restoreFromDisk() async {
    final prefs = await SharedPreferences.getInstance();

    final rawAudience = prefs.getString(_prefsKeyAudience);
    final rawUpdatedAt = prefs.getString(_prefsKeyAudienceUpdatedAt);

    final savedAudience = LocationAudience.fromRaw(rawAudience ?? 'none');
    DateTime? updatedAt;
    if (rawUpdatedAt != null) {
      updatedAt = DateTime.tryParse(rawUpdatedAt);
    }

    final now = DateTime.now();
    final todayReset = DateTime(now.year, now.month, now.day, _resetHour);

    // If we last changed audience before today's reset point → force NONE.
    final effective =
    (updatedAt == null || updatedAt.isBefore(todayReset))
        ? LocationAudience.none
        : savedAudience;

    // Apply like a normal change: persist, Firestore, publisher, timer.
    await _applyAudience(effective);
  }

  // ---------- main API ----------

  Future<void> setAudience(LocationAudience value) async {
    if (state == value) return; // ignore no-op taps
    await _applyAudience(value);
  }

  // ---------- internal helpers ----------

  Future<void> _applyAudience(LocationAudience value) async {
    state = value;

    final now = DateTime.now();
    await _saveToDisk(value, now);

    // Tell publisher + Firestore
    await _publisher.setAudience(value);

    if (value == LocationAudience.none) {
      await _publisher.stop();
    } else {
      await _publisher.start();
    }

    _scheduleDailyReset();
  }

  Future<void> _saveToDisk(LocationAudience value, DateTime when) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyAudience, value.raw);
    await prefs.setString(
      _prefsKeyAudienceUpdatedAt,
      when.toIso8601String(),
    );
  }

  void _scheduleDailyReset() {
    _resetTimer?.cancel();

    final now = DateTime.now();
    final todayReset = DateTime(now.year, now.month, now.day, _resetHour);
    final nextReset =
    now.isBefore(todayReset) ? todayReset : todayReset.add(const Duration(days: 1));

    final duration = nextReset.difference(now);

    _resetTimer = Timer(duration, () async {
      // Only do anything if user is actually sharing
      if (state != LocationAudience.none) {
        await setAudience(LocationAudience.none);
      }
      // Schedule the next day’s reset as well
      _scheduleDailyReset();
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }
}
