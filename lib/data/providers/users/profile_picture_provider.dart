import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../other_providers.dart';
import '../../services/media_existence.dart';
import '../media_existence_provider.dart';

// Lightweight: just checks if the current user's URL string is non-empty
final hasCurrentUserProfilePictureProvider = Provider<bool>((ref) {
  final asyncUser = ref.watch(authUserProvider);
  return asyncUser.maybeWhen(
    data: (u) => (u?.profilePictureUrl?.trim().isNotEmpty ?? false),
    orElse: () => false,
  );
});

final currentUserAvatarHealthProvider =
FutureProvider<MediaExistenceResult>((ref) async {
  final asyncUser = ref.watch(authUserProvider);
  final url = asyncUser.maybeWhen(
    data: (u) => u?.profilePictureUrl,
    orElse: () => null,
  );
  if ((url ?? '').trim().isEmpty) {
    return const MediaExistenceResult(exists: false, downloadUrl: null);
  }
  final media = ref.watch(mediaExistenceProvider);
  return media.check(url!);
});

// Same check but for any user id (live)
final userHasProfilePictureProvider =
StreamProvider.family<bool, String>((ref, uid) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchById(uid).map(
        (u) => (u?.profilePictureUrl?.trim().isNotEmpty ?? false),
  );
});
