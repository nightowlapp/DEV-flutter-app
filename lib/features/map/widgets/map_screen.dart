import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart' hide Viewport;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nightowlcode/data/firestore_paths.dart';
import 'package:nightowlcode/data/providers.dart';
import 'package:nightowlcode/features/map/presentation/map_style.dart';
import 'package:nightowlcode/features/map/widgets/venue_popup.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import '../../../data/repositories/map/map_repository.dart';
import '../../main/widgets/main_app_bar.dart';
import '../../main/widgets/main_screen_right_drawer.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with AutomaticKeepAliveClientMixin {
  MapboxMap? _map;
  final _style = MapStyle();
  late final MapRepository _repo;

  StreamSubscription? _venuesSub;
  StreamSubscription? _friendsSub;

  bool _initialized = false;
  bool _showClosed = false;
  final Set<String> _allowedTypes = {
    'bar', 'club', 'pub', 'beer_bar', 'cocktail_bar', 'wine_bar',
    'sports_bar', 'karaoke_bar', 'gay_bar'
  };

  @override
  void initState() {
    super.initState();
    // _repo = ref.read(mapRepositoryProvider);
  }

  @override
  void dispose() {
    _venuesSub?.cancel();
    _friendsSub?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: MapWidget(
        styleUri: MapboxStyles.MAPBOX_STREETS,
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(12.5683, 55.6761)),
          zoom: 12,
        ),
        onMapCreated: _onMapCreatedOnce,
      ),
    );
  }

  Future<void> _onMapCreatedOnce(MapboxMap map) async {
    if (_initialized) {
      _map ??= map;
      return;
    }
    _initialized = true;
    _map = map;

    await _style.ensure(_map!);
    await _style.applyFilters(_map!, showClosed: _showClosed, allowedTypes: _allowedTypes);

    // Tap handling: venue → popup
    // map.onPointAnnotationTapListener = (annotation) async {
    //   final id = annotation.properties?['id']?.toString() ?? 'unknown';
    //   if (mounted) {
    //     Navigator.of(context).push(
    //       MaterialPageRoute(builder: (_) => VenuePopup(id: id)),
    //     );
    //   }
    // };

    // Subscribe to repos
    final cam = await map.getCameraState();
    final center = cam.center.coordinates;
    final vp = Viewport(center.lat.toDouble(), center.lng.toDouble(), cam.zoom);

    _venuesSub = _repo.watchViewport(vp).listen((venues) async {
      final clusterableVenues = <Map<String, dynamic>>[];
      final payingVenues = <Map<String, dynamic>>[];

      for (final v in venues) {
        if (!_allowedTypes.contains(v.type.name)) continue;
        if (!_showClosed && !v.isOpenToday(DateTime.now())) continue;
        final props = {
          'id': v.id,
          'name': v.displayName,
          'rating': v.rating ?? 0.0,
          'venueType': v.type.name,
          'subscription': v.subscriptionType.name,
        };
        final feat = {
          'type': 'Feature',
          'id': v.id,
          'properties': props,
          'geometry': {'type': 'Point', 'coordinates': [v.entry.lng, v.entry.lat]},
        };

        if (v.subscriptionType == SubscriptionTypesVenue.free) {
          clusterableVenues.add(feat);
        } else {
          payingVenues.add(feat);
        }
      }

      final clusterableFc = jsonEncode({'type': 'FeatureCollection', 'features': clusterableVenues});
      final vipFc = jsonEncode({'type': 'FeatureCollection', 'features': payingVenues});
      final m = _map;
      if (m != null) {
        await _style.setVenueData(m, clusterableFc: clusterableFc, vipFc: vipFc);
      }
    });

    // _friendsSub = _repo.watchFriends(vp).listen((friends) async {
    //   final feats = friends.map((f) => {
    //     'type': 'Feature',
    //     'id': f.id,
    //     'properties': {'id': f.id, 'name': f.name},
    //     'geometry': {'type': 'Point', 'coordinates': [f.lng, f.lat]},
    //   }).toList();
    //   final fc = jsonEncode({'type': 'FeatureCollection', 'features': feats});
    //   final m = _map;
    //   if (m != null) await _style.setFriendsData(m, fc);
    // });
  }
}