import 'dart:async';
import '../../../models/venues/venue.dart';
import '../../repositories/map/geofencing_repository.dart';
import 'geofence_engine.dart';
import 'zones.dart';

/// Orchestrates geofencing based on:
/// - a location stream
/// - a push-updated venues list (no DB stream here)
class GeofencingOrchestrator {
  GeofencingOrchestrator({
    required Stream< ({double lat, double lng})> location$,
    required GeofencingRepository visitRepo,
  }) : _visitRepo = visitRepo,
    _engine = GeofenceEngine(location$: location$, zones: <VenueZone>[])  {
    // React to geofence enter/exit events
    _subs.add(
      _engine.events.listen((e) async {
          if (e.enter) {
            await _visitRepo.enterVenue(e.venueId);            // opens session
          }
          else {
            await _visitRepo.exitVenue(venueId: e.venueId);     // closes session
          }
        }
      ),
    );
  }

  final GeofencingRepository _visitRepo;
  final GeofenceEngine _engine;
  final _subs = <StreamSubscription<dynamic>>[];

  /// Push the latest cached venues here whenever the cache changes.
  void updateVenues(List<Venue> venues) {
    final zones = venues
      .map((v) => zoneFromVenue(v, fallbackRadiusM: 20))
      .toList(growable: false);
    _engine.updateZones(zones);
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _engine.dispose();
  }
}
