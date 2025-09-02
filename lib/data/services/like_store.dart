import 'package:flutter/foundation.dart';
import '../repositories/venues/like_repository.dart';

/// Single Source Of Truth for "is this entity liked by current user?"
class LikeStore extends ChangeNotifier {
  LikeStore({
    required this.entityId,
    required this.getUserId,
    required this.repository,
  });

  final String entityId;
  final String? Function() getUserId;
  final LikesRepository repository;

  bool _ready = false;
  bool _liked = false;
  Object? _lastError;

  bool get ready => _ready;
  bool get isLiked => _liked;
  Object? get lastError => _lastError;

  Future<void> init() async {
    if (_ready) return;
    final uid = getUserId();
    if (uid == null) {
      _ready = true;
      _liked = false;
      notifyListeners();
      return;
    }
    try {
      _liked = await repository.isLiked(userId: uid, entityId: entityId);
      _lastError = null;
    } catch (e) {
      _lastError = e;
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  /// Optimistic toggle; rolls back on failure.
  Future<void> toggle() async {
    if (!_ready) await init();
    final uid = getUserId();
    if (uid == null) {
      throw StateError('Not authenticated');
    }

    final next = !_liked;
    _liked = next;
    notifyListeners();

    try {
      if (next) {
        await repository.like(userId: uid, entityId: entityId);
      } else {
        await repository.unlike(userId: uid, entityId: entityId);
      }
      _lastError = null;
    } catch (e) {
      _liked = !next; // rollback
      _lastError = e;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setLiked()  async { if (!isLiked) await toggle(); }
  Future<void> setUnliked() async { if (isLiked)  await toggle(); }
}
