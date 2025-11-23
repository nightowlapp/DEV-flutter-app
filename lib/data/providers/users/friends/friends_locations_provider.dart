import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/users/live_location.dart';
import '../../../firestore_paths/firestore_paths.dart';
import '../../other_providers.dart';

/// Map<friendUid, LiveLocation> for all friends that have a recent
/// locations/{uid} document.
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

  void watchLocation(String friendUid) {
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
      final loc = LiveLocation.fromDoc(friendUid, data);

      // Hide locations older than 24 hours
      final age = DateTime.now().difference(loc.timestamp);
      if (age > const Duration(hours: 24)) {
        final removed = locations.remove(friendUid) != null;
        if (removed) emit();
        return;
      }

      locations[friendUid] = loc;
      emit();
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

      // Optional: respect i_can_see_them if you use FriendEdge
      final canSee = (data['i_can_see_them'] as bool?) ?? true;
      if (canSee) {
        watchLocation(friendUid);
      } else {
        await unwatchLocation(friendUid);
      }
    }

    // Remove listeners for friends that disappeared from the list
    final toRemove = locSubs.keys
        .where((uid) => !activeFriendIds.contains(uid))
        .toList();
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
