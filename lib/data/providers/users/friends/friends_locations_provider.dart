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
  final visibleLocations = <String, LiveLocation>{};

  // Per-friend subscriptions
  final locSubs =
      <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};
  final closeFlagSubs =
      <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};

  // Last raw data used to recompute visibility
  final lastLocationDocs = <String, Map<String, dynamic>?>{};
  final amCloseFriendForThem = <String, bool>{};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? friendsSub;

  void emit() {
    if (!controller.isClosed) {
      controller.add(Map.unmodifiable(visibleLocations));
    }
  }

  void _removeFriendFromMap(String friendUid) {
    lastLocationDocs.remove(friendUid);
    amCloseFriendForThem.remove(friendUid);
    final removed = visibleLocations.remove(friendUid) != null;
    if (removed) emit();
  }

  /// Recomputes whether [friendUid] should be visible for me,
  /// based on their location audience + whether they marked me as close friend.
  void recomputeVisibility(String friendUid) {
    final raw = lastLocationDocs[friendUid];

    // No location data => remove
    if (raw == null) {
      final removed = visibleLocations.remove(friendUid) != null;
      if (removed) emit();
      return;
    }

    final audienceRaw = raw['audience'] as String?;
    final audience = LocationAudience.fromRaw(audienceRaw);

    // Did THEY mark ME as close friend?
    final theyMarkedMeClose = amCloseFriendForThem[friendUid] ?? false;

    final bool visibleForMe = switch (audience) {
      LocationAudience.none => false,
      // Friends audience: all friends (including close friends)
      LocationAudience.friends => true,
      // Close friends audience: only if they marked me as close friend
      LocationAudience.closeFriends => theyMarkedMeClose,
    };

    if (!visibleForMe) {
      final removed = visibleLocations.remove(friendUid) != null;
      if (removed) emit();
      return;
    }

    try {
      final loc = LiveLocation.fromAny(friendUid, raw);
      visibleLocations[friendUid] = loc;
      emit();
    } catch (_) {
      // ignore malformed data
    }
  }

  Future<void> unwatchFriend(String friendUid) async {
    await locSubs.remove(friendUid)?.cancel();
    await closeFlagSubs.remove(friendUid)?.cancel();
    _removeFriendFromMap(friendUid);
  }

  void watchFriend(String friendUid) {
    // Already watching this friend
    if (locSubs.containsKey(friendUid)) return;

    // 1) Watch their location document: locations/{friendUid}
    final locSub = db
        .collection(FirestoreCollections.locations)
        .doc(friendUid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) {
        lastLocationDocs[friendUid] = null;
        final removed = visibleLocations.remove(friendUid) != null;
        if (removed) emit();
        return;
      }

      lastLocationDocs[friendUid] = doc.data() ?? <String, dynamic>{};
      recomputeVisibility(friendUid);
    }, onError: controller.addError);

    locSubs[friendUid] = locSub;

    // 2) Watch THEIR friend doc for ME:
    // users/{friendUid}/friends/{me.uid}
    final closeSub = db
        .collection('users')
        .doc(friendUid)
        .collection('friends')
        .doc(me.uid)
        .snapshots()
        .listen((doc) {
      amCloseFriendForThem[friendUid] =
          (doc.data()?['is_close_friend'] as bool?) ?? false;
      recomputeVisibility(friendUid);
    }, onError: controller.addError);

    closeFlagSubs[friendUid] = closeSub;
  }

  // Listen to *my* friends list: users/{me}/friends/{friendUid}
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

      // Optional local mute flag. Currently defaults to true and is not used,
      // but keeping it for future "hide this friend" functionality.
      final canSee = (data['i_can_see_them'] as bool?) ?? true;

      if (canSee) {
        watchFriend(friendUid);
      } else {
        await unwatchFriend(friendUid);
      }
    }

    // Unsubscribe from friends that are no longer in my list
    final toRemove =
        locSubs.keys.where((uid) => !activeFriendIds.contains(uid)).toList();
    for (final uid in toRemove) {
      await unwatchFriend(uid);
    }
  }, onError: controller.addError);

  ref.onDispose(() async {
    await friendsSub?.cancel();
    for (final s in locSubs.values) {
      await s.cancel();
    }
    for (final s in closeFlagSubs.values) {
      await s.cancel();
    }
    if (!controller.isClosed) {
      await controller.close();
    }
  });

  return controller.stream;
});
