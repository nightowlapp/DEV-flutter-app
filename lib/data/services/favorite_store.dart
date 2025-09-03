// lib/data/services/favorite_store.dart
import 'package:flutter/foundation.dart';

import '../repositories/venues/favorites_repository.dart';

class FavoriteLimitException implements Exception {
  FavoriteLimitException(this.limit);
  final int limit;
  @override
  String toString() => 'Favorite limit $limit reached';
}

/// SSOT for "is venue favorited by current user?"
class FavoriteStore extends ChangeNotifier {
  FavoriteStore({
    required this.venueId,
    required this.getUserId,
    required this.getIsAdmin, // admins bypass limit
    required this.repository,
    this.maxFavorites = 5,
  });

  final String venueId;
  final String? Function() getUserId;
  final bool Function() getIsAdmin;
  final FavoritesRepository repository;
  final int maxFavorites;

  bool _ready = false;
  bool _isFavorite = false;
  Object? _lastError;
  bool _disposed = false;

  bool get ready => _ready;
  bool get isFavorite => _isFavorite;
  Object? get lastError => _lastError;

  get isFavoriteCount => 5;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> init() async {
    if (_ready) return;
    final uid = getUserId();
    if (uid == null) {
      _ready = true;
      _isFavorite = false;
      _safeNotify();
      return;
    }
    try {
      _isFavorite = await repository.isFavorite(userId: uid, venueId: venueId);
      _lastError = null;
    } catch (e) {
      _lastError = e;
    } finally {
      _ready = true;
      _safeNotify();
    }
  }

  /// Optimistic toggle with limit guard when adding.
  Future<void> toggle() async {
    if (!_ready) await init();
    final uid = getUserId();
    if (uid == null) throw StateError('Not authenticated');

    final next = !_isFavorite;

    if (next && !getIsAdmin()) {
      final current = await repository.countFavorites(userId: uid, atMost: maxFavorites);
      if (current >= maxFavorites) {
        throw FavoriteLimitException(maxFavorites);
      }
    }

    _isFavorite = next;
    _safeNotify();

    try {
      if (next) {
        await repository.addFavorite(userId: uid, venueId: venueId);
      } else {
        await repository.removeFavorite(userId: uid, venueId: venueId);
      }
      _lastError = null;
    } catch (e) {
      _isFavorite = !next; // rollback
      _lastError = e;
      _safeNotify();
      rethrow;
    }
  }
  Future<bool> canAdd() async {
    if (!_ready) await init();
    if (getIsAdmin()) return true;

    final uid = getUserId();
    if (uid == null) throw StateError('Not authenticated');

    final current = await repository.countFavorites(
      userId: uid,
      atMost: maxFavorites, // efficient limit
    );
    return current < maxFavorites;
  }


  Future<void> setFavorite()  async { if (!isFavorite) await toggle(); }
  Future<void> unsetFavorite() async { if (isFavorite)  await toggle(); }
}
