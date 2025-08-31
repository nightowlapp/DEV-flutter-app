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

/// State exposed to the UI
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

/// Ranker knobs that can change live
final rankerRulesProvider = StateProvider<PointRules>((_) => const PointRules());
final userPrefsProvider = StateProvider<UserPrefs?>((_) => null);

/// A ranker built from live rules + prefs
final _venueRankerProvider = Provider<VenueRanker>((ref) {
  final rules = ref.watch(rankerRulesProvider);
  final prefs = ref.watch(userPrefsProvider);
  return VenueRanker(rules: rules, prefs: prefs);
});

class RankedVenuesNotifier extends StateNotifier<AsyncValue<RankedVenuesState>> {
  RankedVenuesNotifier(this.ref) : super(const AsyncLoading()) {
    _init();
  }

  final Ref ref;
  StreamSubscription<List<Venue>>? _venuesSub;
  StreamSubscription<MapEntry<String, VenueMediaHealth>>? _mediaSub;
  List<Venue> _venues = [];
  Map<String, VenueMediaHealth> _media = {};
  Map<String, String> _lastMediaKey = {};
  LatLng? _userLoc;
  final _ranker = const VenueRanker();
  final _svc = VenueMediaService(MediaExistence());

  void _init() {
    // Listen to venues stream
    _venuesSub = ref.watch(allVenuesStreamProvider.stream).listen(
          (venues) {
        print('Venues received: ${venues.length}');
        _venues = venues;
        _updateState();
        _probeMedia(venues);
      },
      onError: (e, stack) {
        print('Firestore venues error: $e\n$stack');
        state = AsyncError(e, stack);
      },
    );

    // Listen to location changes
    ref.listen(currentLatLngProvider, (_, asyncLoc) {
      asyncLoc.when(
        data: (loc) {
          if (_hasMoved(_userLoc, loc, minMeters: 25)) {
            _userLoc = loc;
            _updateState();
          }
        },
        error: (e, stack) => print('Location error: $e\n$stack'),
        loading: () {},
      );
    });

    // Listen to ranker rules/prefs changes
    ref.listen(rankerRulesProvider, (_, __) => _updateState());
    ref.listen(userPrefsProvider, (_, __) => _updateState());
  }

  void _updateState() {
    final ranker = ref.read(_venueRankerProvider);
    final sorted = ranker.sort(_venues, userLocation: _userLoc, media: _media);
    state = AsyncData(RankedVenuesState(
      venues: sorted,
      media: _media,
      userLoc: _userLoc,
    ));
  }

  void _probeMedia(List<Venue> venues) {
    final changed = <Venue>[];
    for (final v in venues) {
      final key = _mediaKey(v);
      if (_lastMediaKey[v.id] != key) {
        _lastMediaKey[v.id] = key;
        changed.add(v);
      }
    }
    if (changed.isEmpty) return;

    _mediaSub?.cancel(); // Cancel previous probes
    _mediaSub = _svc
        .probeVenuesProgressive(
      changed.map(VenueLikeAdapter.new),
      concurrency: 12,
      force: true,
    )
        .listen(
          (entry) {
        _media = {..._media, entry.key: entry.value};
        _updateState();
      },
      onError: (e, stack) {
        print('Media probe error: $e\n$stack');
      },
      onDone: () => _mediaSub = null,
    );
  }

  String _mediaKey(Venue v) =>
      '${v.coverImageUrl ?? ''}|${v.logoUrl ?? ''}|${v.moodImageUrls.join(',')}|${v.updatedAt?.millisecondsSinceEpoch ?? 0}';

  bool _hasMoved(LatLng? a, LatLng? b, {double minMeters = 25}) {
    if (a == null && b == null) return false;
    if (a == null || b == null) return true;
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

  @override
  void dispose() {
    _venuesSub?.cancel();
    _mediaSub?.cancel();
    super.dispose();
  }
}

final rankedVenuesProvider =
StateNotifierProvider.autoDispose<RankedVenuesNotifier, AsyncValue<RankedVenuesState>>((ref) {
  return RankedVenuesNotifier(ref);
});