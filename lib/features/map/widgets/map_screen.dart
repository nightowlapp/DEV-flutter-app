// lib/features/map/widgets/map_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart' hide Viewport;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:nightowlcode/data/providers.dart'; // allVenuesStreamProvider
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/enums.dart'; // <-- VenueType
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/colors.dart';


import '../presentation/map_style.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _map;
  bool _mapCreated = false;
  CameraOptions? _initialCamera;

  ProviderSubscription<AsyncValue<List<Venue>>>? _venuesSub;
  final MapStyle _style = MapStyle();

  // ✅ Use enums here
  final bool _showClosed = true;
  final Set<VenueType> _allowedTypes = const {
    VenueType.bar,
    VenueType.club,
    VenueType.pub,
    VenueType.beer_bar,
    VenueType.cocktail_bar,
    VenueType.wine_bar,
    VenueType.sports_bar,
    VenueType.karaoke_bar,
    VenueType.gay_bar,
  };

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
    // Replace with your location service
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

    // Ensure style and apply filters
    await _style.ensure(_map!);

    // 👇 Convert enums → names only at the boundary to keep MapStyle generic
    await _style.applyFilters(
      _map!,
      showClosed: _showClosed,
      allowedTypes: _allowedTypes.map((e) => e.name).toSet(),
    );

    // Stream all venues → GeoJSON → Mapbox
    _venuesSub = ref.listenManual<AsyncValue<List<Venue>>>(
      allVenuesStreamProvider,
          (prev, next) async {
        if (!mounted || _map == null || !next.hasValue) return;

        final venues = next.value!;
        final clusterable = <Map<String, dynamic>>[];
        final vip = <Map<String, dynamic>>[];

        for (final v in venues) {
          // ✅ Compare enum-to-enum (type-safe)
          if (_allowedTypes.isNotEmpty && !_allowedTypes.contains(v.type)) continue;

          final feat = {
            'type': 'Feature',
            'id': v.id,
            'properties': {
              'id': v.id,
              'name': v.displayName.isNotEmpty ? v.displayName : v.name,
              'rating': v.rating ?? 0.0,
              'venueType': v.type.name,              // <- Mapbox expects string
              'subscription': v.subscriptionType.name,
              'isOpenNow': true,
              'opensLaterToday': true,
            },
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

        await _style.setVenueData(
          _map!,
          clusterableFc: jsonEncode({'type': 'FeatureCollection', 'features': clusterable}),
          vipFc: jsonEncode({'type': 'FeatureCollection', 'features': vip}),
        );
      },
      fireImmediately: true,
    );
  }

  void _centerOnUser() {
    if (_map == null) return;
    //TODO Real user
    const lat = 55.6761, lng = 12.5683;
    _map!.flyTo(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: mapZoomDefault),
      MapAnimationOptions(duration: 800),
    );
  }
  void _openVenueList() {

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
              mini: true, // 24
              tooltip: 'Center on user',
              onPressed: _centerOnUser,
              child:  Icon(locationIcon),
            ),
          ),Positioned(
            bottom: 12,
            right: 60,
            child: FloatingActionButton(
              heroTag: 'mapLegend',
              mini: true,
              tooltip: 'open map legend',
              onPressed: _openVenueList,
              child: Icon(chevronUpIcon),
            ),
          ),
        ],
      ),
    );
  }

}
