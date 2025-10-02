// lib/data/providers/favorites_limit_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/users/user.dart' as model;
import '../../../shared/constants/enums.dart';
import '../other_providers.dart';

/// Map a plan to its limit (central place to change)
final planFavoriteLimitProvider =
Provider.family<int, SubscriptionTypesUser>((ref, plan) {
  switch (plan) {
    case SubscriptionTypesUser.free:    return 5;
    case SubscriptionTypesUser.premium: return 15;
  }
});

/// The signed-in user's current favorite limit (admin = huge).
final favoriteLimitProvider = Provider<int>((ref) {
  const fallback = 5;
  final async = ref.watch(authUserProvider);

  return async.maybeWhen(
    data: (model.User? u) {
      if (u == null) return fallback;
      if (u.isAdmin) return 9999;
      return ref.read(planFavoriteLimitProvider(u.subscriptionType));
    },
    orElse: () => fallback,
  );
});
