// lib/data/providers/users/friends/friends_locations_provider.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/users/live_location.dart';
import '../../../../models/users/location_audience.dart';
import '../../../firestore_paths/firestore_paths.dart';
import '../../other_providers.dart';

final friendsLocationsProvider =
StreamProvider.autoDispose<Map<String, LiveLocation>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final me = auth.currentUser;
  if (me == null) {
    return Stream.value(const <String, LiveLocation>{});
  }

  final db = FirebaseFirestore.instance;

  final controller = StreamController<Map<String, LiveLocation>>();
  final locations = <String, LiveLocation>{};

  final locSubs =
  <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? friendsSub;

  void emit() {
    if (!controller.isClosed) {
      controller.add(Map.unmodifiable(locations));
    }
  }

  Future<void> unwatchLocation(String friendUid) async {
    final sub = locSubs.remove(friendUid);
    await sub?.cancel();
    final removed = locations.remove(friendUid) != null;
    if (removed) emit();
  }

  void watchLocation(
      String friendUid, {
        required bool isCloseFriend,
      }) {
    if (locSubs.containsKey(friendUid)) return;

    final sub = db
        .collection(FirestoreCollections.locations)
        .doc(friendUid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) {
        final removed = locations.remove(friendUid) != null;
        if (removed) emit();
        return;
      }

      final data = doc.data() ?? const <String, dynamic>{};

      final audienceRaw = data['audience'] as String?;
      final audience = LocationAudience.fromRaw(audienceRaw);

      final bool visibleForMe = switch (audience) {
        LocationAudience.none         => false,
        LocationAudience.friends      => true,          // any friend
        LocationAudience.closeFriends => isCloseFriend, // todo not working.
      };

      if (!visibleForMe) {
        final removed = locations.remove(friendUid) != null;
        if (removed) emit();
        return;
      }

      try {
        final loc = LiveLocation.fromAny(friendUid, data);
        locations[friendUid] = loc;
        emit();
      } catch (_) {
        // ignore
      }
    }, onError: controller.addError);

    locSubs[friendUid] = sub;
  }



  // Listen to my friends subcollection: users/{me}/friends/{friendUid}
  friendsSub = db
      .collection('users')
      .doc(me.uid)
      .collection('friends')
      .snapshots()
      .listen((snap) async {
    final activeFriendIds = <String>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      final friendUid = doc.id;
      activeFriendIds.add(friendUid);

      final canSee = (data['i_can_see_them'] as bool?) ?? true;
      final isCloseFriend = (data['is_close_friend'] as bool?) ?? false;

      await unwatchLocation(friendUid);

      if (canSee) {
        watchLocation(
          friendUid,
          isCloseFriend: isCloseFriend,
        );
      }
    }

    final toRemove =
    locSubs.keys.where((uid) => !activeFriendIds.contains(uid)).toList();
    for (final uid in toRemove) {
      await unwatchLocation(uid);
    }
  }, onError: controller.addError);

  ref.onDispose(() async {
    await friendsSub?.cancel();
    for (final s in locSubs.values) {
      await s.cancel();
    }
    if (!controller.isClosed) {
      await controller.close();
    }
  });

  return controller.stream;
});
