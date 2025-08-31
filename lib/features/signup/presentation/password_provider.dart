import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keep password only in memory (never persisted to SharedPreferences).
final passwordProvider = StateProvider<String>((ref) => '');

/// Simple gate for min length (6)
final passwordMinOkProvider = Provider<bool>((ref) {
  final p = ref.watch(passwordProvider);
  return p.trim().length >= 6;
});
