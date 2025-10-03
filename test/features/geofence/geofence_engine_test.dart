// test/features/geofence/geofence_engine_test.dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/data/services/geofencing/zones.dart';
import 'package:nightowlcode/data/services/geofencing/geofence_engine.dart';

/// --- Fake repo that mirrors the new GeofencingRepository semantics ---
class _Session {
  final String id;
  final String venueId;
  DateTime enteredAt;
  DateTime? exitedAt;
  final String source;
  _Session(this.id, this.venueId, this.enteredAt, this.source);
}

class FakeGeofencingRepository {
  final List<_Session> _sessions = [];
  int _id = 0;

  List<_Session> get sessions => List.unmodifiable(_sessions);

  Future<String> enterVenue(String venueId, {String source = 'geofence'}) async {
    // already open for same venue? -> no-op
    for (final s in _sessions) {
      if (s.exitedAt == null && s.venueId == venueId) return s.id;
    }
    // close any open (other venues), then open one for venueId
    for (final s in _sessions) {
      if (s.exitedAt == null) s.exitedAt = DateTime.now();
    }
    final id = (++_id).toString();
    _sessions.add(_Session(id, venueId, DateTime.now(), source));
    return id;
  }

  Future<void> exitVenue({String? venueId}) async {
    for (final s in _sessions) {
      final match = s.exitedAt == null && (venueId == null || s.venueId == venueId);
      if (match) s.exitedAt = DateTime.now();
    }
  }
}

void main() {
  // --------------------- your existing engine-only tests ---------------------

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

    loc.add((lat: 55.0, lng: 12.0));
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

    expect(
      events.map((e) => '${e.enter ? 'enter' : 'exit'}:${e.venueId}').toList(),
      ['enter:A', 'exit:A'],
    );
  });

  // --------------------- new: repo + engine integration tests ---------------------

  test('repo idempotency: repeated ENTER for same venue does not create a new session', () async {
    final loc = StreamController<({double lat, double lng})>();
    addTearDown(() => loc.close());

    final zoneA = const VenueZone(
      venueId: 'A',
      polygon: [],
      center: LatLng(55.0, 12.0),
      radiusM: 40,
    );

    final engine = GeofenceEngine(
      location$: loc.stream,
      zones: <VenueZone>[zoneA],
      dwell: const Duration(milliseconds: 80),
    );
    addTearDown(engine.dispose);

    final repo = FakeGeofencingRepository();
    final sub = engine.events.listen((e) {
      if (e.enter) {
        repo.enterVenue(e.venueId);
      } else {
        repo.exitVenue(venueId: e.venueId);
      }
    });
    addTearDown(sub.cancel);

    // Enter A once (engine → repo.enterVenue)
    loc.add((lat: 55.0, lng: 12.0));
    await Future.delayed(const Duration(milliseconds: 120));

    expect(repo.sessions.length, 1);
    expect(repo.sessions.first.venueId, 'A');
    expect(repo.sessions.first.exitedAt, isNull);

    // Simulate a duplicate ENTER for A (e.g., spurious engine event)
    await repo.enterVenue('A');
    expect(repo.sessions.length, 1, reason: 'idempotent: same venue should not create a new doc');
    expect(repo.sessions.first.exitedAt, isNull);
  });

  test('switch venue: closing A then opening B (atomic semantics)', () async {
    final loc = StreamController<({double lat, double lng})>();
    addTearDown(() => loc.close());

    final zoneA = VenueZone(
      venueId: 'A',
      polygon: const [],
      center: const LatLng(55.0, 12.0),
      radiusM: 40,
    );
    final zoneB = VenueZone(
      venueId: 'B',
      polygon: const [],
      center: const LatLng(55.0008, 12.0008), // ~100m away
      radiusM: 40,
    );

    final engine = GeofenceEngine(
      location$: loc.stream,
      zones: <VenueZone>[zoneA, zoneB],
      dwell: const Duration(milliseconds: 80),
    );
    addTearDown(engine.dispose);

    final repo = FakeGeofencingRepository();
    final sub = engine.events.listen((e) {
      if (e.enter) {
        repo.enterVenue(e.venueId);
      } else {
        repo.exitVenue(venueId: e.venueId);
      }
    });
    addTearDown(sub.cancel);

    // Enter A
    loc.add((lat: 55.0, lng: 12.0));
    await Future.delayed(const Duration(milliseconds: 120));

    // Move into B (engine should emit exit:A then enter:B)
    loc.add((lat: 55.0008, lng: 12.0008));
    await Future.delayed(const Duration(milliseconds: 120));

    // Expect 2 sessions total: A (closed), B (open)
    expect(repo.sessions.length, 2);
    final sA = repo.sessions.firstWhere((s) => s.venueId == 'A');
    final sB = repo.sessions.firstWhere((s) => s.venueId == 'B');
    expect(sA.exitedAt, isNotNull, reason: 'A must be closed when switching to B');
    expect(sB.exitedAt, isNull, reason: 'B should be the only open session');
  });

  test('EXIT sets exited_at and does not create new sessions', () async {
    final loc = StreamController<({double lat, double lng})>();
    addTearDown(() => loc.close());

    final zoneA = VenueZone(
      venueId: 'A',
      polygon: const [],
      center: const LatLng(55.0, 12.0),
      radiusM: 40,
    );

    final engine = GeofenceEngine(
      location$: loc.stream,
      zones: <VenueZone>[zoneA],
      dwell: const Duration(milliseconds: 80),
    );
    addTearDown(engine.dispose);

    final repo = FakeGeofencingRepository();
    final sub = engine.events.listen((e) {
      if (e.enter) {
        repo.enterVenue(e.venueId);
      } else {
        repo.exitVenue(venueId: e.venueId);
      }
    });
    addTearDown(sub.cancel);

    // Enter A
    loc.add((lat: 55.0, lng: 12.0));
    await Future.delayed(const Duration(milliseconds: 120));
    expect(repo.sessions.length, 1);
    expect(repo.sessions.first.exitedAt, isNull);

    // Move far outside → EXIT
    loc.add((lat: 55.01, lng: 12.01)); // far outside radius
    await Future.delayed(const Duration(milliseconds: 120));

    expect(repo.sessions.length, 1, reason: 'no new sessions on exit');
    expect(repo.sessions.first.exitedAt, isNotNull, reason: 'exit should set exited_at');
  });
}
