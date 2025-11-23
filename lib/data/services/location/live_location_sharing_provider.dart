import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/providers/other_providers.dart';
import 'package:nightowlcode/features/map/widgets/share_location_popup.dart'
    show ShareAudience;

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
StateNotifierProvider<ShareAudienceController, ShareAudience>((ref) {
  final pub = ref.read(liveLocationPublisherProvider);
  final controller = ShareAudienceController(pub);

  // Optional: if user logs out, stop sharing
  ref.listen(firebaseAuthProvider, (prev, next) {
    if (next.currentUser == null) {
      controller.setAudience(ShareAudience.none);
    }
  });

  return controller;
});

class ShareAudienceController extends StateNotifier<ShareAudience> {
  ShareAudienceController(this._publisher) : super(ShareAudience.none);

  final LiveLocationPublisher _publisher;

  Future<void> setAudience(ShareAudience value) async {
    if (state == value) return;
    state = value;

    if (value == ShareAudience.none) {
      await _publisher.stop();
    } else {
      // friends OR closeFriends → we publish the same way for now
      await _publisher.start();
    }
  }
}
