import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/storage/user_local_store.dart';
import '../../../features/explore/ranking/venue_ranker_prefs.dart';
import '../../../models/users/user.dart' as model;
import '../other_providers.dart'; // authStateProvider, userRepositoryProvider

final userPrefsProvider = StateProvider<UserPrefs?>((_) => null);

/// 🔎 Find any user by uid (stream).
/// Returns `null` if the document does not exist.
final userByUidProvider =
    StreamProvider.family<model.User?, String>((ref, uid) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchById(uid); // Stream<model.User?>
});

/// Require a non-null user (widgets/providers can wait on loading)
final meRequiredAvProvider = Provider<AsyncValue<model.User>>((ref) {
  final av = ref.watch(meSsoProvider); // AsyncValue<model.User?>
  return av.when(
    data: (u) => u == null
        ? const AsyncError('signed out', StackTrace.empty)
        : AsyncData(u),
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
  );
});

/// Synchronous “give me the best you have now or null”
final meOptionalProvider =
    Provider<model.User?>((ref) => ref.watch(meSsoProvider).valueOrNull);

/// Preferences derived from the real user (async)
final mePrefsAvProvider = Provider<AsyncValue<UserPrefs>>((ref) {
  final meAv = ref.watch(meRequiredAvProvider);
  return meAv.when(
    data: (u) => AsyncData(UserPrefs.fromUser(u)),
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
  );
});

/// Optional: just the uid when you need to tag writes quickly
final meUidProvider =
    Provider<String?>((ref) => ref.watch(meOptionalProvider)?.id);

final meLocalStoreProvider =
    Provider<MeLocalStore>((ref) => MeLocalStore(ref.watch(sharedPrefsProvider)));

final meSsoProvider = AsyncNotifierProvider<MeSso, model.User?>(MeSso.new);

class MeSso extends AsyncNotifier<model.User?> {
  StreamSubscription<model.User?>? _sub;
  String? _boundUid;

  @override
  Future<model.User?> build() async {
    ref.keepAlive();
    final cache = ref.watch(meLocalStoreProvider);
    final repo = ref.watch(userRepositoryProvider);

    // 🔁 Rebuild when auth state changes
    final authAv = ref.watch(authStateProvider); // StreamProvider<fb.User?>
    final fbUser = authAv.valueOrNull;

    if (fbUser == null) {
      // Signed out → stop, clear cache, emit null
      await _sub?.cancel();
      _sub = null;
      _boundUid = null;
      await cache.clear();
      state = const AsyncData(null);
      return null;
    }

    // ⚡ Fast paint from cache if matches current uid
    final cached = await cache.read();
    if (cached?.id == fbUser.uid) {
      state = AsyncData(cached);
    } else {
      state = const AsyncLoading();
    }

    // 🔗 Rebind live Firestore stream when uid changes
    if (_boundUid != fbUser.uid) {
      await _sub?.cancel();
      _boundUid = fbUser.uid;

      _sub = repo.watchById(fbUser.uid).listen(
        (u) async {
          state = AsyncData(u);
          if (u != null) await cache.write(u); // keep prefs cache warm
        },
        onError: (e, s) => state = AsyncError(e, s),
      );
    }

    ref.onDispose(() async => _sub?.cancel());
    return state.valueOrNull;
  }
}
