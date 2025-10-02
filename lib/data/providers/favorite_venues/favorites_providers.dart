// lib/data/providers/favorites_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/services/favorite_store.dart';
import 'package:nightowlcode/data/repositories/venues/favorites_repository.dart';
import '../../../core/storage/firestore_favorites_data_source.dart';
import '../other_providers.dart';
import 'favorite_limit_provider.dart';

final favoritesDataSourceProvider = Provider<FavoritesDataSource>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirestoreFavoritesDataSource(db);
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(favoritesDataSourceProvider));
});

// Simpler: pass only venueId. Limit/admin are derived inside.
final favoriteStoreProvider =
ChangeNotifierProvider.family.autoDispose<FavoriteStore, String>((ref, venueId) {
  ref.watch(authStateProvider); // refresh on auth changes
  final repo = ref.watch(favoritesRepositoryProvider);
  final maxFavorites = ref.watch(favoriteLimitProvider);

  String? getUserId() => ref.read(firebaseAuthProvider).currentUser?.uid;

  bool getIsAdmin() {
    final async = ref.read(authUserProvider);
    return async.maybeWhen(data: (u) => (u?.isAdmin ?? false), orElse: () => false);
  }

  final store = FavoriteStore(
    venueId: venueId,
    getUserId: getUserId,
    getIsAdmin: getIsAdmin,
    repository: repo,
    maxFavorites: maxFavorites,
  );

  // keep alive until first init completes (prevents dispose/notify race)
  final link = ref.keepAlive();
  store.init().whenComplete(() => link.close());

  return store;
});

/// Live count of favorites for the signed-in user.
final favoritesCountProvider = StreamProvider<int>((ref) {
  final auth = ref.watch(authStateProvider).value; // fb.User?
  if (auth == null) return Stream<int>.value(0);
  final repo = ref.watch(favoritesRepositoryProvider);
  return repo.watchFavoritesCount(userId: auth.uid);
});

/// Combines current count + limit in one place.
final favoritesProgressProvider = Provider<({int current, int limit, bool unlimited})>((ref) {
  final current = ref.watch(favoritesCountProvider).maybeWhen(
    data: (c) => c, orElse: () => 0,
  );
  final limit = ref.watch(favoriteLimitProvider);
  final unlimited = limit >= 9999;
  return (current: current, limit: limit, unlimited: unlimited);
});
