// lib/features/explore/presentation/ranked_venues_controller.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightowlcode/data/providers.dart';
import 'package:nightowlcode/features/explore/utility/venue_ranker.dart';
import 'package:nightowlcode/features/explore/utility/venue_ranker_prefs.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

import '../../../data/repositories/venues/venue_media_adapter.dart';
import '../../../data/services/location/location_controller.dart';
import '../../../data/services/media_existence.dart';

/// -------- Public state exposed to the UI
class RankedVenuesState {
  final List<Venue> venues; // sorted
  final Map<String, VenueMediaHealth> media;
  final LatLng? userLoc;
  const RankedVenuesState({
    required this.venues,
    required this.media,
    required this.userLoc,
  });
}

/// -------- Ranker knobs that can change live (watch these to re-sort immediately)
final rankerRulesProvider = StateProvider<PointRules>((_) => const PointRules());
final userPrefsProvider = StateProvider<UserPrefs?>((_) => null);

/// A ranker built from live rules + prefs.
final _venueRankerProvider = Provider<VenueRanker>((ref) {
  final rules = ref.watch(rankerRulesProvider);
  final prefs = ref.watch(userPrefsProvider);
  return VenueRanker(rules: rules, prefs: prefs);
});

/// Optional: how often to poll user location if you don't have a real stream.
const _locationPollInterval = Duration(seconds: 15);

/// -------- Main stream consumed by the UI.
/// Emits nothing until the FIRST full sort completes.
final rankedVenuesProvider =
StreamProvider.autoDispose<RankedVenuesState>((ref) async* {
  final venues$ = ref.watch(allVenuesStreamProvider.stream);
  final mediaSvc = VenueMediaService(MediaExistence());

  // Mutable state shared by the listeners
  List<Venue> _venues = const [];
  LatLng? _userLoc;
  Map<String, VenueMediaHealth> _media = {};
  final Map<String, String> _lastMediaKey = {}; // venueId -> fingerprint

  // Output stream
  final out = StreamController<RankedVenuesState>.broadcast();
  ref.onDispose(() => out.close());

  // Helper: sort & emit
  void _emitSorted() {
    final ranker = ref.read(_venueRankerProvider);
    final sorted =
    ranker.sort(_venues, userLocation: _userLoc, media: _media);
    out.add(RankedVenuesState(venues: sorted, media: _media, userLoc: _userLoc));
  }

  // ---- Poll user location (don’t block initial emit)
  Timer? locTimer;
  bool _firstLocationResolved = false;

  Future<void> _sampleLocationOnce() async {
    try {
      final loc = await ref.read(currentLatLngProvider.future).timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      if (!_firstLocationResolved || _hasMoved(_userLoc, loc, minMeters: 25)) {
        _userLoc = loc;
        _firstLocationResolved = true;
        _emitSorted();
      }
    } catch (_) {
      // keep previous userLoc (null or last good)
    }
  }

  // Start location sampling (initial + periodic)
  unawaited(_sampleLocationOnce());
  locTimer = Timer.periodic(_locationPollInterval, (_) => _sampleLocationOnce());
  ref.onDispose(() => locTimer?.cancel());

  // React immediately to ranker rules/prefs changes
  final cancelRules =
  ref.listen<PointRules>(rankerRulesProvider, (_, __) => _emitSorted());
  final cancelPrefs =
  ref.listen<UserPrefs?>(userPrefsProvider, (_, __) => _emitSorted());
  ref.onDispose(() {
    cancelRules.close();
    cancelPrefs.close();
  });

  // ---- Block until first venues snapshot → initial full sort
  _venues = await venues$.first;
  _emitSorted();

  // After initial emit, listen for subsequent venue updates
  final subVenues = venues$.skip(1).listen((vns) {
    _venues = vns;
    _emitSorted(); // re-sort immediately (don’t wait for media)

    // Probe media only for venues whose fingerprint changed
    final changed = <Venue>[];
    for (final v in vns) {
      final key =
          '${v.coverImageUrl ?? ''}|${v.logoUrl ?? ''}|${v.moodImageUrls.join(',')}|${v.updatedAt?.millisecondsSinceEpoch ?? 0}';
      if (_lastMediaKey[v.id] != key) {
        _lastMediaKey[v.id] = key;
        changed.add(v);
      }
    }
    if (changed.isNotEmpty) {
      _probeMediaProgressive(
        ref: ref,
        svc: mediaSvc,
        venues: changed,
        onEach: (entry) {
          _media = Map.of(_media)..[entry.key] = entry.value;
          _emitSorted(); // media affects score → re-sort as we learn
        },
      );
    }
  });
  ref.onDispose(() => subVenues.cancel());

  // Stream to UI
  yield* out.stream;
});

bool _hasMoved(LatLng? a, LatLng? b, {double minMeters = 25}) {
  if (a == null && b == null) return false;
  if (a == null || b == null) return true;

  // Equirectangular approximation (fast & accurate for small deltas)
  const R = 6371000.0; // meters
  const deg2rad = math.pi / 180.0;

  final phi1 = a.lat * deg2rad;
  final phi2 = b.lat * deg2rad;
  final dPhi = (b.lat - a.lat) * deg2rad;
  final dLambda = (b.lng - a.lng) * deg2rad;

  final phiM = (phi1 + phi2) / 2.0;
  final x = dLambda * math.cos(phiM);
  final dist = math.sqrt(dPhi * dPhi + x * x) * R;
  return dist >= minMeters;
}

/// Progressive media probing with bounded concurrency using your existing service.
void _probeMediaProgressive({
  required AutoDisposeStreamProviderRef<RankedVenuesState> ref,
  required VenueMediaService svc,
  required List<Venue> venues,
  required void Function(MapEntry<String, VenueMediaHealth>) onEach,
}) {
  try {
    final stream = svc.probeVenuesProgressive(
      venues.map(VenueLikeAdapter.new),
      concurrency: 12,
      force: true,
    );
    final sub = stream.listen(onEach);
    ref.onDispose(() => sub.cancel());
  } catch (_) {
    // Fallback: sequential probe
    scheduleMicrotask(() async {
      for (final v in venues) {
        try {
          final r = await svc.probe(
            coverRefOrUrl: v.coverImageUrl,
            logoRefOrUrl: v.logoUrl,
            moodRefsOrUrls: v.moodImageUrls,
            force: true,
          );
          onEach(MapEntry(v.id, r));
        } catch (_) {}
      }
    });
  }
}
