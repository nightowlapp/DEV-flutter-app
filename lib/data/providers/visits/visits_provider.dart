// lib/data/providers/users/visits_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/users/visit_session.dart';
import '../../../models/venues/venue.dart';
import '../other_providers.dart';
import 'my_visits_session_provider.dart';

class VisitUi {
  final Venue venue;
  final int visits;
  const VisitUi({required this.venue, required this.visits});
}

final myVisitsWithVenuesProvider = Provider<List<VisitUi>>((ref) {
  final sessions = ref.watch(myVisitSessionsProvider).maybeWhen(
    data: (v) => v,
    orElse: () => const <VisitSession>[],
  );
  final venues = ref.watch(venuesListProvider);
  final byId = {for (final v in venues) v.id: v};

  // Count sessions per venue_id
  final counts = <String, int>{};
  for (final s in sessions) {
    counts.update(s.venueId, (c) => c + 1, ifAbsent: () => 1);
  }

  // Build UI list, ignore sessions for venues we don't have locally
  final out = <VisitUi>[];
  counts.forEach((venueId, cnt) {
    final v = byId[venueId];
    if (v != null) out.add(VisitUi(venue: v, visits: cnt));
  });

  // Sort by visits desc (or lastVisited if you want)
  out.sort((a, b) => b.visits.compareTo(a.visits));
  return out;
});
