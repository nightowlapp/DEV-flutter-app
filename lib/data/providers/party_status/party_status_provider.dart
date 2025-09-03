// lib/shared/reusable/users/party_status_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

import '../../../shared/party_status_store.dart';

// Map PartyStatusTypes -> Color (same mapping you use in the indicator)
Color statusToColor(PartyStatusTypes s) {
  switch (s) {
    case PartyStatusTypes.out_tonight: return green;
    case PartyStatusTypes.house_party: return purple;
    case PartyStatusTypes.pregame:     return yellow;
    case PartyStatusTypes.recovering:  return red;
    case PartyStatusTypes.still_planning:
    default:                           return greyLighter;
  }
}

/// Current party status (last saved), as a color.
/// Recomputed when invalidated (e.g. after saveStatus).
final partyStatusColorProvider = FutureProvider<Color>((ref) async {
  final store = ref.watch(partyStatusStoreProvider);
  final s = await store.loadStatus();
  return statusToColor(s ?? PartyStatusTypes.still_planning);
});
