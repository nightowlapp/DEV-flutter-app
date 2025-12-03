import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/users/friend.dart';
import '../../../../models/users/live_location.dart';
import '../../../firestore_paths/firestore_paths.dart';
import 'friends_locations_provider.dart';

/// Keeps a live in-memory Map<uid, FriendProfile> for everyone that
/// currently has a LiveLocation (except yourself).
final friendProfilesProvider =
    StateNotifierProvider<FriendProfilesNotifier, Map<String, FriendProfile>>(
  (ref) {
    final notifier = FriendProfilesNotifier();

    // Whenever the set of uids with locations changes, sync watchers.
    ref.listen<AsyncValue<Map<String, LiveLocation>>>(
      friendsLocationsProvider,
      (prev, next) {
        next.whenData((locs) {
          notifier.setTrackedUids(locs.keys.toSet());
        });
      },
    );

    ref.onDispose(notifier.dispose);
    return notifier;
  },
);

class FriendProfilesNotifier extends StateNotifier<Map<String, FriendProfile>> {
  FriendProfilesNotifier() : super(const {});

  final _db = FirebaseFirestore.instance;
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _subs = {};

  Set<String> _tracked = const {};

  void setTrackedUids(Set<String> uids) {
    final newOnes = uids.difference(_tracked);
    final gone = _tracked.difference(uids);
    _tracked = uids;

    for (final uid in newOnes) {
      _start(uid);
    }
    for (final uid in gone) {
      _stop(uid);
    }
  }

  void _start(String uid) {
    if (_subs.containsKey(uid)) return;

    final sub = _db
        .collection(FirestoreCollections.users)
        .doc(uid)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) {
        final copy = {...state}..remove(uid);
        state = copy;
        return;
      }

      final data = snap.data() ?? const <String, dynamic>{};
      final profile = FriendProfile.fromUserDoc(uid, data);
      state = {...state, uid: profile};
    });

    _subs[uid] = sub;
  }

  Future<void> _stop(String uid) async {
    final sub = _subs.remove(uid);
    await sub?.cancel();
    final copy = {...state}..remove(uid);
    state = copy;
  }

  @override
  void dispose() {
    for (final s in _subs.values) {
      s.cancel();
    }
    super.dispose();
  }
}
