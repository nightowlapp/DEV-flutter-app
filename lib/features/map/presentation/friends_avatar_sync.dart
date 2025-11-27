// e.g. lib/features/map/presentation/friends_avatar_sync.dart

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../models/users/friend.dart';
import 'map_registry/map_images_registry.dart';

Future<void> syncFriendAvatarsToMap({
  required MapboxMap map,
  required Map<String, FriendProfile> profiles,
}) async {
  final images = <String, String>{};

  profiles.forEach((uid, profile) {
    final status = profile.partyStatus?.name ?? 'still_planning';
    final spriteId = 'friend_avatar_${uid}_$status';

    final photo = profile.photoUrl?.trim();
    if (photo != null && photo.isNotEmpty) {
      images[spriteId] = photo; // real photo
    } else {
      images[spriteId] = 'placeholder://friend'; // 👈 sentinel
    }
  });

  await MapImageRegistry.instance.syncIdToUrl(
    map: map,
    images: images,
    maxSize: 32,
    pixelRatio: 2.0,
  );
}
