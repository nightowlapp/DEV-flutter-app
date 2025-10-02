import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/venues/venue.dart';
import '../../repositories/map/geofencing_repository.dart';
import '../../services/geofencing/geofencing_orchestrator.dart';
import '../../services/location/location_providers.dart';
import '../other_providers.dart';

final geofencingOrchestratorProvider =
Provider.autoDispose<GeofencingOrchestrator?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final uid = auth.currentUser?.uid;
  if (uid == null) return null;

  // ✅ Use the safe stream
  final locStream = ref.watch(latLngSafeStreamProvider.stream);
  final location$ = locStream.map((p) => (lat: p.lat, lng: p.lng));

  final repo = GeofencingRepository(uid);
  final geoOrch = GeofencingOrchestrator(
    location$: location$,
    visitRepo: repo,
  );

  // Seed + keep in sync with cached venues
  final initialVenues = ref.read(venuesListProvider);
  geoOrch.updateVenues(initialVenues);

  ref.listen<List<Venue>>(venuesListProvider, (prev, next) {
    geoOrch.updateVenues(next);
  });

  ref.onDispose(geoOrch.dispose);
  return geoOrch;
});
