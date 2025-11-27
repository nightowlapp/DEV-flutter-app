import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/enums.dart'; // PartyStatusTypes
import '../../../../models/users/user.dart' as model;
import '../../../firestore_paths/firestore_paths.dart';
import 'find_friends_providers.dart';
import 'friends_provider.dart';
import 'sorted_friends_provider.dart';

final userSearchQueryProvider = StateProvider<String>((_) => '');

/// You can provide the signed-in user’s current location here (if you have it).
/// If null, distances fall back to server-provided `distance_m` or become
/// `infinity` (sorted last).
final myLocationProvider = Provider<GeoPoint?>((_) => null);

/// Composite ranking key. Lower wins.
class _RankKey implements Comparable<_RankKey> {
  const _RankKey({
    required this.distanceM,
    required this.noImageFirst,
    required this.partyRank,
    required this.missingFields, // completeness: fewer missing = better
  });

  final double distanceM; // ascending
  final int noImageFirst; // 0 if has image, 1 otherwise
  final int partyRank; // lower = better (see mapping below)
  final int missingFields; // lower = better

  @override
  int compareTo(_RankKey other) {
    final c1 = distanceM.compareTo(other.distanceM);
    if (c1 != 0) return c1;

    final c2 = noImageFirst.compareTo(other.noImageFirst);
    if (c2 != 0) return c2;

    final c3 = partyRank.compareTo(other.partyRank);
    if (c3 != 0) return c3;

    return missingFields.compareTo(other.missingFields);
  }
}

/// ---- Helpers ----------------------------------------------------------------

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

/// Best-effort distance: prefers server-provided `distance_m`,
/// then tries GeoPoint / last_known_lat|lon; otherwise Infinity.
double _distanceForUser(Map<String, dynamic> data, GeoPoint? myOrigin) {
  final server = (data['distance_m'] as num?)?.toDouble() ??
      (data['distance'] as num?)?.toDouble();
  if (server != null) return server;

  GeoPoint? gp;

  // Common schemas:
  if (data['location'] is GeoPoint) {
    gp = data['location'] as GeoPoint;
  } else {
    final lat =
    (data[LocationDocumentPaths.lastKnownLat] as num?)?.toDouble();
    final lon =
    (data[LocationDocumentPaths.lastKnownLon] as num?)?.toDouble();
    if (lat != null && lon != null) {
      gp = GeoPoint(lat, lon);
    }
  }

  if (gp == null || myOrigin == null) return double.infinity;
  return _haversine(myOrigin, gp);
}

/// Returns party ranking score (lower = better) based on your order:
/// out_tonight (best), house_party, pregame, still_planning, recovering, else.
int _partyRank(dynamic raw) {
  PartyStatusTypes? status;

  // Firestore may store as string name or as index. Handle both.
  if (raw is String) {
    final s = raw.toLowerCase();
    for (final v in PartyStatusTypes.values) {
      if (v.name.toLowerCase() == s) {
        status = v;
        break;
      }
    }
  } else if (raw is int) {
    if (raw >= 0 && raw < PartyStatusTypes.values.length) {
      status = PartyStatusTypes.values[raw];
    }
  } else if (raw is PartyStatusTypes) {
    status = raw;
  }

  // Map to rank (lower = better). Unspecified → large number (worst).
  switch (status) {
    case PartyStatusTypes.out_tonight:
      return 0;
    case PartyStatusTypes.house_party:
      return 1;
    case PartyStatusTypes.pregame:
      return 2;
    case PartyStatusTypes.still_planning:
      return 3;
    case PartyStatusTypes.recovering:
      return 400;
    default:
      return 9; // not_tonight / heading_home / null / unknown
  }
}

/// How “complete” the public profile looks: count how many important fields are
/// missing or empty. Fewer missing → better.
int _missingProfileFields(Map<String, dynamic> data) {
  // Curate this list to what you actually show in profile UI.
  const fields = <String>[
    'display_full_name',
    UserDocumentPaths.userName,
    'bio',
    'gender',
    'birthday',
    UserDocumentPaths.profilePictureUrl,
    'home_city',
    'interests', // List or map
    'favorite_venue_ids', // List
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
  return ((data[UserDocumentPaths.profilePictureUrl] as String?)
      ?.isNotEmpty ??
      false) ||
      ((data['profilePictureUrl'] as String?)?.isNotEmpty ?? false);
}

/// ---- Provider ----------------------------------------------------------------

final suggestedUsersProvider = StreamProvider<List<model.User>>((ref) {
  final me = ref.watch(authUserIdProvider);
  final q = ref.watch(userSearchQueryProvider);
  final db = FirebaseFirestore.instance;

  final friends = ref.watch(friendUidsProvider).maybeWhen(
    data: (ids) => ids.toSet(),
    orElse: () => <String>{},
  );
  final incoming = ref.watch(incomingFriendRequestsProvider).maybeWhen(
    data: (l) => l.map((e) => e.fromUid).toSet(),
    orElse: () => <String>{},
  );
  final outgoing = ref.watch(outgoingFriendRequestsProvider).maybeWhen(
    data: (l) => l.map((e) => e.toUid).toSet(),
    orElse: () => <String>{},
  );

  final myOrigin = ref.watch(myLocationProvider);

  if (me == null) return const Stream.empty();

  Query<Map<String, dynamic>> base =
  db.collection(UserDocumentPaths.collection);

  if (q.trim().length >= 2) {
    final s = q.trim().toLowerCase();
    base = base
        .orderBy(UserDocumentPaths.userNameLower) // 'user_name_lc'
        .startAt([s])
        .endAt(['$s\uf8ff'])
        .limit(25);
  } else {
    base =
        base.orderBy(UserDocumentPaths.createdAt, descending: true).limit(25);
  }

  return base.snapshots().map((snap) {
    final items = <(_RankKey, model.User)>[];

    for (final d in snap.docs) {
      final data = d.data();

      // Exclusions you already had
      if (d.id == me) continue;
      if (friends.contains(d.id)) continue;
      if (incoming.contains(d.id)) continue;
      if (outgoing.contains(d.id)) continue;

      final rank = _RankKey(
        distanceM: _distanceForUser(data, myOrigin),
        noImageFirst: _hasImage(data) ? 0 : 1,
        partyRank: _partyRank(
          data[UserDocumentPaths.currentPartyStatus],
        ),
        missingFields: _missingProfileFields(data),
      );

      final user = model.User.fromJson({'id': d.id, ...data});
      items.add((rank, user));
    }

    items.sort((a, b) => a.$1.compareTo(b.$1));
    return items.map((e) => e.$2).toList(growable: false);
  });
});
