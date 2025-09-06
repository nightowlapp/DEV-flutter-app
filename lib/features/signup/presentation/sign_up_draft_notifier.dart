import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/storage/app_storage.dart';
import 'sign_up_draft.dart';

class SignUpDraftNotifier extends StateNotifier<SignUpDraft> {
  SignUpDraftNotifier(this._prefs) : super(_load(_prefs));
  final SharedPreferences _prefs;
  static const _k = 'signup_draft';

  static SignUpDraft _load(SharedPreferences p) {
    final raw = p.getString(_k);
    if (raw == null) return const SignUpDraft();
    try { return SignUpDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>); }
    catch (_) { return const SignUpDraft(); }
  }

  void _save() => _prefs.setString(_k, jsonEncode(state.toJson()));

  // Mutations
  void setBirthdate(DateTime d) { state = state.copyWith(birthdate: d); _save(); }
  void setUsername(String u)    { state = state.copyWith(username: u.trim()); _save(); }
  void setGender(g)             { state = state.copyWith(gender: g); _save(); }
  void setEmail(String e)       { state = state.copyWith(email: e.trim()); _save(); }
  void setLocalPhoto(String p)  { state = state.copyWith(localPhotoPath: p); _save(); }
  void setRemotePhoto(String u) { state = state.copyWith(remotePhotoUrl: u); _save(); }
  void setAcceptedTos(bool v)   { state = state.copyWith(acceptedTos: v); _save(); }
  void clear()                  { state = const SignUpDraft(); _prefs.remove(_k); }

  /// Generic merge that keeps this layer free of Firebase imports.
  void mergeExternalProfile({String? displayName, String? email, String? photoUrl}) {
    state = state.copyWith(
      username: state.username ?? (displayName?.trim().isEmpty ?? true ? null : displayName!.trim()),
      email: state.email ?? (email?.trim().isEmpty ?? true ? null : email!.trim().toLowerCase()),
      remotePhotoUrl: state.remotePhotoUrl ?? photoUrl,
    );
    _save();
  }
}

// --- Selectors (computed state) ---
bool _isAtLeastAge(DateTime d, int age) {
  final now = DateTime.now();
  final cutoff = DateTime(now.year - age, now.month, now.day);
  return !d.isAfter(cutoff);
}

final ageOkProvider = Provider<bool>((ref) {
  final d = ref.watch(signUpDraftProvider);
  return d.birthdate != null && _isAtLeastAge(d.birthdate!, 18);
});

final canContinueFirstStepProvider = Provider<bool>((ref) {
  final d = ref.watch(signUpDraftProvider);
  final ageOk = ref.watch(ageOkProvider);
  return ageOk && d.acceptedTos;
});

/// Public provider
final signUpDraftProvider =
StateNotifierProvider<SignUpDraftNotifier, SignUpDraft>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);        // central instance
  return SignUpDraftNotifier(prefs);
});
