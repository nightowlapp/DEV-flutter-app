class LikesRepository {
  LikesRepository(this._ds);
  final LikesDataSource _ds;

  Future<bool> isLiked({
    required String userId,
    required String entityId,
  }) =>
      _ds.isLiked(userId: userId, entityId: entityId);

  Future<void> like({
    required String userId,
    required String entityId,
  }) =>
      _ds.like(userId: userId, entityId: entityId);

  Future<void> unlike({
    required String userId,
    required String entityId,
  }) =>
      _ds.unlike(userId: userId, entityId: entityId);
}

abstract class LikesDataSource {
  Future<bool> isLiked({required String userId, required String entityId});
  Future<void> like({required String userId, required String entityId});
  Future<void> unlike({required String userId, required String entityId});
}
