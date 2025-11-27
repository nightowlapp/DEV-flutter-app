// lib/data/providers/users/friends/friends_locations_provider.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/users/live_location.dart';
import '../../../firestore_paths/firestore_paths.dart';
import '../../other_providers.dart';

/// For now: show **all users** in `locations` (except myself).
final friendsLocationsProvider =
StreamProvider.autoDispose<Map<String, LiveLocation>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final me = auth.currentUser;
  if (me == null) {
    return Stream.value(const <String, LiveLocation>{});
  }

  final db = FirebaseFirestore.instance;

  final snapshots =
  db.collection(FirestoreCollections.locations).snapshots();

  return snapshots.map((qs) {
    final now = DateTime.now();
    final out = <String, LiveLocation>{};

    // 👇 debug
    // ignore: avoid_print
    print(
        '[friendsLocationsProvider] locations snapshot: ${qs.docs.length} docs');

    for (final doc in qs.docs) {
      final uid = doc.id;

      // Skip myself (so you see "everyone else")
      if (uid == me.uid) continue;

      final data = doc.data();

      try {
        final loc = LiveLocation.fromAny(uid, data);

        // // Hide locations older than 7 days hours
        // if (now.difference(loc.timestamp) > const Duration(days: 7)) {
        //   continue;
        // }

        out[uid] = loc;
      } catch (e) {
        // ignore malformed doc but log once
        // ignore: avoid_print
        print(
            '[friendsLocationsProvider] failed to parse $uid: $e, data=$data');
      }
    }

    // ignore: avoid_print
    print(
        '[friendsLocationsProvider] emitting ${out.length} live locations');

    return out;
  });
});
