import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/venues/venue.dart';
import '../../repositories/map/geofencing_repository.dart';
import '../../services/geofencing/geofencing_orchestrator.dart';
import '../../services/location/location_providers.dart';
import '../other_providers.dart';
import '../venues/venue_providers.dart';

// Geofencing orchestrator wired to SSO + location
final geofencingOrchestratorProvider =
Provider.autoDispose<GeofencingOrchestrator?>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return null;

  // Keep it alive even if UI temporarily drops the watch.
  final link = ref.keepAlive();

  final location$ = ref
      .watch(latLngSafeStreamProvider.stream) // Stream<LatLng>
      .map((p) => (lat: p.lat, lng: p.lng));

  final repo = GeofencingRepository(user.uid);
  final orch = GeofencingOrchestrator(location$: location$, visitRepo: repo);

  // Seed with current cached venues
  orch.updateVenues(ref.read(allVenuesListProvider));

  // Keep zones in sync with SSO updates
  ref.listen<List<Venue>>(allVenuesListProvider, (prev, next) {
    if (!identical(prev, next)) {
      orch.updateVenues(next);
    }
  });

  ref.onDispose(() {
    link.close();
    orch.dispose();
  });

  return orch;
});
