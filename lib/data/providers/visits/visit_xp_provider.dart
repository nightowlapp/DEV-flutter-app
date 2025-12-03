// lib/data/providers/users/visit_xp_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/users/visit_session.dart';
import '../../../shared/utility/level_logic.dart';
import 'my_visits_session_provider.dart';

/// Total XP earned from all visit sessions (all venues).
final myVisitXpProvider = Provider<int>((ref) {
  final sessionsAv = ref.watch(myVisitSessionsProvider);

  return sessionsAv.maybeWhen(
    data: _calculateVisitXpFromSessions,
    orElse: () => 0,
  );
});

int _calculateVisitXpFromSessions(List<VisitSession> sessions) {
  // Group sessions per venue so we can know "visit #N" for that venue
  final byVenue = <String, List<VisitSession>>{};
  for (final s in sessions) {
    byVenue.putIfAbsent(s.venueId, () => <VisitSession>[]).add(s);
  }

  var totalXp = 0;

  byVenue.forEach((venueId, list) {
    // Sort by enteredAt so visitNumberForVenue is consistent
    list.sort((a, b) {
      final aTime = a.enteredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.enteredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });

    var visitNumber = 0;

    for (final s in list) {
      visitNumber++;

      final entered = s.enteredAt;
      final exited = s.exitedAt;

      final duration = (entered != null && exited != null)
          ? exited.difference(entered)
          : Duration.zero;

      totalXp += LevelLogic.xpForVenueVisit(
        stayDuration: duration,
        visitNumberForVenue: visitNumber,
      );
    }
  });

  return totalXp;
}
