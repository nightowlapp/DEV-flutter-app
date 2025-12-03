// lib/data/providers/users/friends/friend_suggestions_provider.dart

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/social/utility/friend_requests_section.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

import '../../../../models/users/user.dart' as model;
import '../../../firestore_paths/firestore_paths.dart';
import 'friend_request_provider.dart';
import 'friends_provider.dart';
import 'sorted_friends_provider.dart' show authUserIdProvider;
import '../../../../shared/party_priority.dart'; // partyPriority()

// ----------------------------------------------------------------------------
// Search text from the "Find Friends" TextField
// ----------------------------------------------------------------------------

final userSearchQueryProvider = StateProvider.autoDispose<String>((_) => '');

// Optional: your own location → ranking by distance
final myLocationProvider = Provider<GeoPoint?>((_) => null);

// Users that should NEVER appear in Find Friends
const Set<String> _neverSuggestUserIds = {
  'NaguneV9N3eFZr6S1gKxuzSnNSl1', // Test
  'aTGWCoqqmXT5ijqTbntWEuFWWvh2', // Nightowl
};

// ----------------------------------------------------------------------------
// Ranking key
// ----------------------------------------------------------------------------

class _RankKey implements Comparable<_RankKey> {
  const _RankKey({
    required this.searchRank,
    required this.distanceM,
    required this.noImageFirst,
    required this.partyPriorityRank,
    required this.missingFields,
  });

  final int searchRank; // lower = better match to query
  final double distanceM; // closer first
  final int noImageFirst; // 0 if has image, 1 otherwise
  final int partyPriorityRank; // lower = better (out tonight > ...)
  final int missingFields; // fewer missing profile fields is better

  @override
  int compareTo(_RankKey other) {
    final c0 = searchRank.compareTo(other.searchRank);
    if (c0 != 0) return c0;

    final c1 = distanceM.compareTo(other.distanceM);
    if (c1 != 0) return c1;

    final c2 = noImageFirst.compareTo(other.noImageFirst);
    if (c2 != 0) return c2;

    final c3 = partyPriorityRank.compareTo(other.partyPriorityRank);
    if (c3 != 0) return c3;

    return missingFields.compareTo(other.missingFields);
  }
}

// ----------------------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------------------

double _toRad(double deg) => deg * math.pi / 180.0;

double _haversine(GeoPoint a, GeoPoint b) {
  const r = 6371000.0; // meters
  final dLat = _toRad(b.latitude - a.latitude);
  final dLon = _toRad(b.longitude - a.longitude);
  final la1 = _toRad(a.latitude);
  final la2 = _toRad(b.latitude);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(la1) * math.cos(la2) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return 2 * r * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}

double _distanceForUser(Map<String, dynamic> data, GeoPoint? myOrigin) {
  GeoPoint? gp;

  if (data['location'] is GeoPoint) {
    gp = data['location'] as GeoPoint;
  } else {
    final lat = (data[LocationDocumentPaths.lastKnownLat] as num?)?.toDouble();
    final lon = (data[LocationDocumentPaths.lastKnownLon] as num?)?.toDouble();
    if (lat != null && lon != null) {
      gp = GeoPoint(lat, lon);
    }
  }

  if (gp == null || myOrigin == null) return double.infinity;
  return _haversine(myOrigin, gp);
}

int _missingProfileFields(Map<String, dynamic> data) {
  const fields = <String>[
    'first_name',
    'last_name',
    UserDocumentPaths.userName,
    'biography',
    UserDocumentPaths.profilePictureUrl,
    'home_town',
    'interests',
    'favorite_venue_ids',
    'instagram',
    'tiktok',
    'snapchat',
  ];

  int missing = 0;
  for (final k in fields) {
    final v = data[k];
    final isMissing = v == null ||
        (v is String && v.trim().isEmpty) ||
        (v is Iterable && v.isEmpty) ||
        (v is Map && v.isEmpty);
    if (isMissing) missing++;
  }
  return missing;
}

bool _hasImage(Map<String, dynamic> data) {
  return ((data[UserDocumentPaths.profilePictureUrl] as String?)?.isNotEmpty ??
          false) ||
      ((data['profilePictureUrl'] as String?)?.isNotEmpty ?? false);
}

/// lower = better match
int _searchRank(String q, String usernameLc, String fullNameLc) {
  if (q.isEmpty) return 5;

  if (usernameLc.startsWith(q)) return 0;
  if (fullNameLc.startsWith(q)) return 1;
  if (usernameLc.contains(q)) return 2;
  if (fullNameLc.contains(q)) return 3;
  return 4;
}

// ----------------------------------------------------------------------------
// Main provider
// ----------------------------------------------------------------------------

const _maxDocsPerQuery = 60; // cap Firestore reads per search

final suggestedUsersProvider =
    StreamProvider.autoDispose<List<model.User>>((ref) {
  final me = ref.watch(authUserIdProvider);
  if (me == null) return const Stream.empty();

  final qRaw = ref.watch(userSearchQueryProvider);
  final db = FirebaseFirestore.instance;

  final friends = ref.watch(friendUidsProvider).maybeWhen(
        data: (ids) => ids.toSet(),
        orElse: () => <String>{},
      );

  final incomingPending = ref.watch(incomingFriendRequestsProvider).maybeWhen(
        data: (reqs) =>
            reqs.where((r) => r.statusIsPending).map((r) => r.fromUid).toSet(),
        orElse: () => <String>{},
      );

  final outgoingPending = ref.watch(outgoingFriendRequestsProvider).maybeWhen(
        data: (reqs) =>
            reqs.where((r) => r.statusIsPending).map((r) => r.toUid).toSet(),
        orElse: () => <String>{},
      );

  final myOrigin = ref.watch(myLocationProvider);

  final q = qRaw.trim();
  final s = q.toLowerCase();

  Query<Map<String, dynamic>> base =
      db.collection(UserDocumentPaths.collection);

  // Optional length gate to save reads — uncomment if you want it:
  // if (s.length < 2 && q.isNotEmpty) {
  //   return const Stream<List<model.User>>.empty();
  // }

  if (s.isEmpty) {
    // "Discovery" mode – newest users
    base = base
        .orderBy(UserDocumentPaths.createdAt, descending: true)
        .limit(_maxDocsPerQuery);
  } else {
    // If query has a space, treat as full name search, else username search
    final bool looksLikeName = s.contains(' ');
    final field = looksLikeName
        ? UserDocumentPaths.displayFullNameLower
        : UserDocumentPaths.userNameLower;

    base = base
        .orderBy(field)
        .startAt([s]).endAt(['$s\uf8ff']).limit(_maxDocsPerQuery);
  }

  return base.snapshots().map((snap) {
    final items = <(_RankKey, model.User)>[];

    for (final d in snap.docs) {
      final data = d.data();

      // Hard excludes
      if (_neverSuggestUserIds.contains(d.id)) continue;
      if (d.id == me) continue;
      if (friends.contains(d.id)) continue;
      if (incomingPending.contains(d.id)) continue;
      if (outgoingPending.contains(d.id)) continue;

      final user = model.User.fromJson({'id': d.id, ...data});

      final usernameLc = user.userName.toLowerCase();
      final fullNameLc = user.displayFullName.toLowerCase();

      final rank = _RankKey(
        searchRank: _searchRank(s, usernameLc, fullNameLc),
        distanceM: _distanceForUser(data, myOrigin),
        noImageFirst: _hasImage(data) ? 0 : 1,
        partyPriorityRank: partyPriority(user.currentPartyStatus),
        missingFields: _missingProfileFields(data),
      );

      items.add((rank, user));
    }

    items.sort((a, b) => a.$1.compareTo(b.$1));
    return items.map((e) => e.$2).toList(growable: false);
  });
});
