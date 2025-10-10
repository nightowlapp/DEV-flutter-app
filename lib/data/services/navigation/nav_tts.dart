// lib/features/navigation/services/nav_tts.dart
import 'package:flutter_tts/flutter_tts.dart';

class NavTts {
  final FlutterTts _tts = FlutterTts();

  Future<void> init({String language = 'en-US'}) async {
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    // iOS: await _tts.setSharedInstance(true); // if you need other audio mixing
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    if (text.trim().isEmpty) return;
    await _tts.speak(text);
  }

  Future<void> dispose() async => _tts.stop();
}
