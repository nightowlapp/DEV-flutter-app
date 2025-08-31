// lib/data/services/geofencing/geofencing_orchestrator.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../../models/venues/venue.dart';


import '../../../shared/utility/lat_lng.dart';
import '../../repositories/map/geofencing_repository.dart';
import 'geofence_engine.dart';
import 'zones.dart';             // VenueZone + zoneFromVenue

class GeofencingOrchestrator {
  GeofencingOrchestrator({
    required Stream<({double lat, double lng})> location$,
    required Stream<List<Venue>> venues$,
    required GeofencingRepository presenceRepo,
  })  : _presenceRepo = presenceRepo,
        _engine = GeofenceEngine(location$: location$, zones: const []) {
    _subs.add(
      venues$.listen((vs) {
        final zones = vs.map((v) => zoneFromVenue(v, fallbackRadiusM: 20)).toList();
        _engine.updateZones(zones);
      }),
    );
    _subs.add(
      _engine.events.listen((e) async {
        if (e.enter) {
          await _presenceRepo.enterVenue(_presenceRepo.userId, e.venueId, _presenceRepo.db);
        } else {
          await _presenceRepo.exitVenue(_presenceRepo.userId, _presenceRepo.db);
        }
      }),
    );
  }

  final GeofencingRepository _presenceRepo;
  final GeofenceEngine _engine;
  final _subs = <StreamSubscription>[];

  void dispose() {
    for (final s in _subs) { s.cancel(); }
    _engine.dispose();
  }
}
