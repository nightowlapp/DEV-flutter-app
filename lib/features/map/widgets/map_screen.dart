// lib/features/map/widgets/map_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart' hide Viewport;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:nightowlcode/data/providers.dart'; // allVenuesStreamProvider
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

import '../presentation/map_style.dart'; // MapStyle

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _map;
  bool _mapCreated = false;
  CameraOptions? _initialCamera;

  // Riverpod subscription (listenManual since we subscribe outside build)
  ProviderSubscription<AsyncValue<List<Venue>>>? _venuesSub;

  // Filters (per your earlier setup)
  final bool _showClosed = true; // show everything initially
  final Set<String> _allowedTypes = const {
    'bar', 'club', 'pub', 'beer_bar', 'cocktail_bar', 'wine_bar',
    'sports_bar', 'karaoke_bar', 'gay_bar'
  };

  final MapStyle _style = MapStyle();

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _venuesSub?.close();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      // Replace with your real location service if available
      const lat = 55.6761; // Copenhagen
      const lng = 12.5683;
      setState(() {
        _initialCamera = CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          zoom: mapZoomDefault,
          pitch: 0,
          bearing: 0,
        );
      });
    } catch (_) {
      setState(() {
        _initialCamera = CameraOptions(
          center: Point(coordinates: Position(12.5683, 55.6761)),
          zoom: 12.0,
        );
      });
    }
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    if (_mapCreated) return;
    _map = map;
    _mapCreated = true;

    await _map!.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        accuracyRingColor: owlOrange.value,
        accuracyRingBorderColor: white.value,
        showAccuracyRing: true,
      ),
    );
    await _map!.scaleBar.updateSettings(ScaleBarSettings(enabled: false, isMetricUnits: true));
    await _map!.attribution
        .updateSettings(AttributionSettings(clickable: false, iconColor: transparent.value));

    // Ensure sources/layers and apply filters
    await _style.ensure(_map!);
    await _style.applyFilters(_map!, showClosed: _showClosed, allowedTypes: _allowedTypes);

    // Listen to ALL venues and push to Mapbox sources
    _venuesSub = ref.listenManual<AsyncValue<List<Venue>>>(
      allVenuesStreamProvider,
          (prev, next) async {
        if (!mounted || _map == null || !next.hasValue) return;
        final venues = next.value!;
        final clusterable = <Map<String, dynamic>>[];
        final vip = <Map<String, dynamic>>[];

        for (final v in venues) {
          if (_allowedTypes.isNotEmpty && !_allowedTypes.contains(v.type.name)) continue;

          final props = <String, dynamic>{
            'id': v.id,
            'name': v.displayName.isNotEmpty ? v.displayName : v.name,
            'rating': v.rating ?? 0.0,
            'venueType': v.type.name,
            'subscription': v.subscriptionType.name,
            // keep pins green for now; wire real hours later
            'isOpenNow': true,
            'opensLaterToday': true,
          };

          final feat = {
            'type': 'Feature',
            'id': v.id,
            'properties': props,
            'geometry': {
              'type': 'Point',
              'coordinates': [v.entry.lng, v.entry.lat],
            },
          };

          if (v.subscriptionType == SubscriptionTypesVenue.free) {
            clusterable.add(feat);
          } else {
            vip.add(feat);
          }
        }

        final clusterableFc =
        jsonEncode({'type': 'FeatureCollection', 'features': clusterable});
        final vipFc = jsonEncode({'type': 'FeatureCollection', 'features': vip});

        await _style.setVenueData(_map!, clusterableFc: clusterableFc, vipFc: vipFc);
      },
      fireImmediately: true,
    );
  }

  void _centerOnUser() {
    if (_map == null) return;
    const lat = 55.6761;
    const lng = 12.5683;
    _map!.flyTo(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: mapZoomDefault),
      MapAnimationOptions(duration: 800),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialCamera == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('mapWidget'),
            styleUri: MapboxStyles.SATELLITE,
            cameraOptions: _initialCamera!,
            onMapCreated: _onMapCreated,
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: FloatingActionButton(
              heroTag: 'centerUser',
              mini: true,
              tooltip: 'Center on user',
              onPressed: _centerOnUser,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
