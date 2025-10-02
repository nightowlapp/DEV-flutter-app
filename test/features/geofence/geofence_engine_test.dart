import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/data/services/geofencing/zones.dart';
import 'package:nightowlcode/data/services/geofencing/geofence_engine.dart';

void main() {
  test('emits enter when staying inside without further ticks (timer dwell)', () async {
    final loc = StreamController<({double lat, double lng})>();
    addTearDown(() => loc.close());

    final zone = VenueZone(
      venueId: 'A',
      polygon: const [],
      center: const LatLng(55.0, 12.0),
      radiusM: 30,
    );

    final engine = GeofenceEngine(
      location$: loc.stream,
      zones: <VenueZone>[zone],
      dwell: const Duration(milliseconds: 150),
    );

    final events = <GeofenceEvent>[];
    final sub = engine.events.listen(events.add);
    addTearDown(() { sub.cancel(); engine.dispose(); });

    // Single tick inside the zone; no more ticks after this.
    loc.add((lat: 55.0, lng: 12.0));

    // Wait longer than dwell; the timer should commit the enter.
    await Future.delayed(const Duration(milliseconds: 250));

    expect(events.length, 1);
    expect(events.first.enter, isTrue);
    expect(events.first.venueId, 'A');
  });

  test('enter then exit after moving out', () async {
    final loc = StreamController<({double lat, double lng})>();
    addTearDown(() => loc.close());

    final zone = VenueZone(
      venueId: 'A',
      polygon: const [],
      center: const LatLng(55.0, 12.0),
      radiusM: 30,
    );

    final engine = GeofenceEngine(
      location$: loc.stream,
      zones: <VenueZone>[zone],
      dwell: const Duration(milliseconds: 100),
    );

    final events = <GeofenceEvent>[];
    final sub = engine.events.listen(events.add);
    addTearDown(() { sub.cancel(); engine.dispose(); });

    loc.add((lat: 55.0, lng: 12.0)); // inside
    await Future.delayed(const Duration(milliseconds: 150));

    loc.add((lat: 55.0006, lng: 12.0006)); // ~75m away (outside radius 30m)
    await Future.delayed(const Duration(milliseconds: 150));

    expect(events.map((e) => '${e.enter ? 'enter' : 'exit'}:${e.venueId}').toList(),
        ['enter:A', 'exit:A']);
  });
}
