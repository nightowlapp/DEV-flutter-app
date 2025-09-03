// lib/data/repositories/venues/favorite_repository.dart
abstract class FavoritesDataSource {
  Future<bool> isFavorite({required String userId, required String venueId});
  Future<void> addFavorite({required String userId, required String venueId});
  Future<void> removeFavorite({required String userId, required String venueId});
  Future<int> countFavorites({required String userId, int? atMost});
  Stream<int> watchCount({required String userId});
  Stream<List<String>> watchFavoriteVenueIds({required String userId});
}

class FavoritesRepository {
  FavoritesRepository(this._ds);
  final FavoritesDataSource _ds;

  Future<bool> isFavorite({required String userId, required String venueId}) =>
      _ds.isFavorite(userId: userId, venueId: venueId);

  Future<void> addFavorite({required String userId, required String venueId}) =>
      _ds.addFavorite(userId: userId, venueId: venueId);

  Future<void> removeFavorite({required String userId, required String venueId}) =>
      _ds.removeFavorite(userId: userId, venueId: venueId);

  Future<int> countFavorites({required String userId, int? atMost}) =>
      _ds.countFavorites(userId: userId, atMost: atMost);

  Stream<int> watchFavoritesCount({required String userId}) =>
      _ds.watchCount(userId: userId);

  Stream<List<String>> watchFavoriteVenueIds({required String userId}) =>
      _ds.watchFavoriteVenueIds(userId: userId);
}
