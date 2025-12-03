// lib/features/navigation/services/nav_tts.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavTts {
  static const _kMutedKey = 'nav_tts_muted';

  final FlutterTts _tts = FlutterTts();
  SharedPreferences? _prefs;

  bool _muted = false;
  final ValueNotifier<bool> muted = ValueNotifier(false);

  bool get isMuted => _muted;

  Future<void> init({String language = 'en-US'}) async {
    _prefs = await SharedPreferences.getInstance();
    _muted = _prefs?.getBool(_kMutedKey) ?? false;
    muted.value = _muted;

    await _tts.setLanguage(language);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    // await _tts.setSharedInstance(true); // iOS optional
  }

  Future<void> setMuted(bool value) async {
    _muted = value;
    muted.value = value;
    if (value) {
      try {
        await _tts.stop();
      } catch (_) {}
    }
    await _prefs?.setBool(_kMutedKey, value);
  }

  Future<void> toggleMuted() => setMuted(!isMuted);

  Future<void> speak(String text) async {
    if (_muted) return;
    final t = text.trim();
    if (t.isEmpty) return;
    try {
      await _tts.stop();
    } catch (_) {}
    await _tts.speak(t);
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {}
    muted.dispose();
  }
}
