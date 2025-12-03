// lib/data/providers/users/sorted_friends_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/models/users/user.dart' as model;
import 'friends_provider.dart';

final _authStateProvider = StreamProvider<fb.User?>(
    (ref) => fb.FirebaseAuth.instance.authStateChanges());

final authUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(_authStateProvider).value;
  return auth?.uid;
});

const Map<PartyStatusTypes, int> _partyPriority = {
  PartyStatusTypes.out_tonight: 0,
  PartyStatusTypes.house_party: 1,
  PartyStatusTypes.pregame: 2,
  PartyStatusTypes.recovering: 3,
  PartyStatusTypes.still_planning: 4,
};
int _p(PartyStatusTypes s) => _partyPriority[s] ?? 999;

final sortedFriendsProvider = Provider<List<model.User>>((ref) {
  final me = ref.watch(authUserIdProvider);

  final all = ref.watch(friendsProvider).maybeWhen(
        data: (v) => v,
        orElse: () => const <model.User>[],
      );

  final list =
      all.where((u) => me == null ? true : u.id != me).toList(growable: false);

  list.sort((a, b) {
    final pa = _p(a.currentPartyStatus);
    final pb = _p(b.currentPartyStatus);
    if (pa != pb) return pa.compareTo(pb);

    final an = a.userName.trim().toLowerCase();
    final bn = b.userName.trim().toLowerCase();
    final byName = an.compareTo(bn);
    if (byName != 0) return byName;

    return a.id.compareTo(b.id);
  });

  return list;
});
