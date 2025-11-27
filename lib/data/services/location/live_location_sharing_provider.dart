// lib/data/services/location/live_location_sharing_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/providers/other_providers.dart';
import 'package:nightowlcode/models/users/location_audience.dart';

import 'live_location_publisher.dart';

/// Singleton LiveLocationPublisher, auto-stopped when provider is disposed.
final liveLocationPublisherProvider = Provider<LiveLocationPublisher>((ref) {
  final pub = LiveLocationPublisher();
  ref.onDispose(() => pub.stop());
  return pub;
});

/// Current sharing audience (friends / closeFriends / none).
/// This also starts/stops the LiveLocationPublisher.
final shareAudienceProvider =
StateNotifierProvider<ShareAudienceController, LocationAudience>((ref) {
  final pub = ref.read(liveLocationPublisherProvider);
  final controller = ShareAudienceController(pub);

  // If user logs out, stop sharing + reset.
  ref.listen(firebaseAuthProvider, (prev, next) {
    if (next.currentUser == null) {
      controller.setAudience(LocationAudience.none);
    }
  });

  return controller;
});

class ShareAudienceController extends StateNotifier<LocationAudience> {
  ShareAudienceController(this._publisher) : super(LocationAudience.none);

  final LiveLocationPublisher _publisher;

  Future<void> setAudience(LocationAudience value) async {
    if (state == value) return;

    state = value;

    // 1) always persist the new audience
    await _publisher.setAudience(value);

    // 2) start/stop streaming
    if (value == LocationAudience.none) {
      await _publisher.stop();
    } else {
      // friends OR closeFriends
      await _publisher.start();
    }
  }
}
