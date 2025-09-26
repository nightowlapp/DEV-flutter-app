// lib/features/map/widgets/map_screen.dart
import 'package:flutter/material.dart' hide Viewport;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nightowlcode/features/map/widgets/venue_popup.dart';

import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

import '../../../core/storage/storage_url.dart';
import '../../../data/other_providers.dart';
import '../../../data/services/location/location_controller.dart';
import '../../../data/providers/venues/venue_providers.dart';
import '../presentation/map_logo_registry.dart';
import '../presentation/map_style.dart';
import '../presentation/initial_camera_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
  with AutomaticKeepAliveClientMixin {
  MapboxMap? _map;
  bool _mapCreated = false;
  bool _loading = true;
  bool _styleReady = false;

  final MapStyle _style = MapStyle();
  final Map<String, Venue> _venuesById = {};
  String _logoImageIdFor(Venue v) =>
  'logo_${v.id}_${(v.updatedAt ?? v.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).millisecondsSinceEpoch}';

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
  bool get wantKeepAlive => true;

  Future<void> _onMapCreated(MapboxMap map) async {
    if (_mapCreated) return;
    _map = map;
    _mapCreated = true;

    await _map!.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        accuracyRingColor: blue.value,
        accuracyRingBorderColor: white.value,
        showAccuracyRing: true,
      ),
    );
    await _map!.scaleBar.updateSettings(
      ScaleBarSettings(enabled: false, isMetricUnits: true),
    );
    await _map!.attribution.updateSettings(
      AttributionSettings(clickable: false, iconColor: transparent.value),
    );
  }

  // fly helper (your custom LatLng -> Mapbox CameraOptions)
  Future<void> _navigateTo(LatLng location, {double zoom = 16}) async {
    if (_map == null) return;
    final cam = CameraOptions(
      center: Point(coordinates: Position(location.lng, location.lat)),
      zoom: zoom,
      pitch: 0,
      bearing: 0,
    );
    _map!.flyTo(cam, MapAnimationOptions(duration: 800));
  }

  void _openVenueById(String id) {
    final v = _venuesById[id];
    if (v == null) return;
    // fly then open sheet
    _navigateTo(v.entry);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => VenuePopup(
        venue: v,
        onClose: () => Navigator.of(context).pop(),
        onOpenDetails: () {},
      ),
    );
  }

  // include BOTH bg circle layers and the symbol layers to catch all taps
  // _onMapTap: use a small ScreenBox and include cluster layers.
  // include BOTH bg circle layers and the symbol layers to catch all taps
  Future<void> _onMapTap(MapContentGestureContext ctx) async {
    final map = _map;
    if (map == null) return;

    Map<String, dynamic>? asMap(Object? o) =>
    (o is Map) ? o.cast<String, dynamic>() : null;
    List<dynamic>? asList(Object? o) => (o is List) ? o : null;

    // 32×32 px hit box around the finger
    final p = ctx.touchPosition;
    const half = 16.0;
    final geometry = RenderedQueryGeometry.fromScreenBox(
      ScreenBox(
        min: ScreenCoordinate(x: p.x - half, y: p.y - half),
        max: ScreenCoordinate(x: p.x + half, y: p.y + half),
      ),
    );

    // Pull an id out of queried features
    String? _firstId(List<QueriedRenderedFeature?> items) {
      for (final r in items) {
        if (r == null) continue;
        final feat = r.queriedFeature.feature as Map?;
        final props = asMap(feat?['properties']);
        final rawId = props?['id'] ?? props?['venue_id'] ?? props?['venueId'] ?? feat?['id'];
        if (rawId != null) return rawId.toString();
      }
      return null;
    }

    // 1) Symbols (on top)
    final List<QueriedRenderedFeature?> sym = await map.queryRenderedFeatures(
      geometry,
      RenderedQueryOptions(layerIds: [MapStyle.lyrVip, MapStyle.lyrUnclustered]),
    );
    final symId = _firstId(sym);
    if (symId != null) {
      _openVenueById(symId);
      return;
    }

    // 2) Background circles
    final List<QueriedRenderedFeature?> dots = await map.queryRenderedFeatures(
      geometry,
      RenderedQueryOptions(layerIds: [MapStyle.lyrVipBg, MapStyle.lyrUnclusteredBg]),
    );
    final dotId = _firstId(dots);
    if (dotId != null) {
      _openVenueById(dotId);
      return;
    }

    // 3) Clusters -> zoom toward the cluster center
    final List<QueriedRenderedFeature?> cl = await map.queryRenderedFeatures(
      geometry,
      RenderedQueryOptions(layerIds: [MapStyle.lyrClusters]),
    );
    for (final r in cl) {
      if (r == null) continue;
      final feat = r.queriedFeature.feature as Map?;
      final props = asMap(feat?['properties']);
      if (props?['point_count'] != null) {
        final coords = asList(asMap(feat?['geometry'])?['coordinates']);
        if (coords != null && coords.length >= 2) {
          final lon = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();
          final cs = await map.getCameraState();
          map.easeTo(
            CameraOptions(
              center: Point(coordinates: Position(lon, lat)),
              zoom: (cs.zoom + 1.6).clamp(3.0, 20.0),
            ),
            MapAnimationOptions(duration: 500),
          );
        }
        return;
      }
    }
  }

  Future<void> _centerOnUser() async {
    final cam = await ref.read(initialCameraProvider.future);
    _map?.flyTo(cam, MapAnimationOptions(duration: 1200));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.listen<VenuesFc>(venuesGeoJsonProvider, (prev, next) async {
        final map = _map;
        if (map == null || !_styleReady) return;

        await _style.setVenueData(
          map,
          clusterableFc: next.clusterable,
          vipFc: next.vip,
        );

        // Build the set of logo IDs we need (use the exact string used by icon-image)
        final venues = ref.read(venuesListProvider);
        final idToPath2 = <String, String>{};
        for (final v in venues) {
          if (v.isVerified) {
            final id = _logoImageIdFor(v);
            // Prefer your canonical path; ignore arbitrary external URLs here
            idToPath2[id] = 'venue_images/${v.id}/logo.webp';
          }
        }
        await MapLogoRegistry.instance.syncIdToUrl(map: map, images: idToPath2);
      }
    );

    // 🔄 Use the SSO-backed map for popups (no direct Firestore stream)
    ref.listen<Map<String, Venue>>(venuesByIdMapProvider, (prev, next) {
        _venuesById
        ..clear()
        ..addAll(next);
      }
    );

    // center animation updates
    ref.listen<AsyncValue<CameraOptions>>(initialCameraProvider, (prev, next) {
        next.whenData((cam) => _map?.flyTo(cam, MapAnimationOptions(duration: 650)));
      }
    );

    final camAsync = ref.watch(initialCameraProvider);
    final cam = camAsync.maybeWhen(data: (c) => c, orElse: () => fallbackCamera);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('mapWidget'),
            styleUri: "mapbox://styles/night-owl/cmfzfrida004u01s5co906aj5",
            cameraOptions: cam,
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            onTapListener: _onMapTap,
          ),
          if (_loading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: Center(child: LoadingIndicator()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        tooltip: 'Center on user',
        onPressed: _centerOnUser,
        child: Icon(locationIcon),
      ),
    );
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    final map = _map;
    if (map == null || _styleReady) return;
    _styleReady = true;

    MapLogoRegistry.instance.clear();

    await _style.ensure(map);
    await _style.applyFilters(
      map,
      showClosed: _showClosed,
      allowedTypes: _allowedTypes.map((e) => e.name).toSet(),
    );

    final fcNow = ref.read(venuesGeoJsonProvider);
    await _style.setVenueData(map, clusterableFc: fcNow.clusterable, vipFc: fcNow.vip);

    // First-time sync right after style is ready
    final venues = ref.read(venuesListProvider);
    final idToPath = <String, String>{};
    for (final v in venues) {
      if (!v.isVerified) continue;
      final id = _logoImageIdFor(v);
      idToPath[id] = 'venue_images/${v.id}/logo.webp';
    }
    await MapLogoRegistry.instance.syncIdToUrl(map: map, images: idToPath);

    if (mounted) setState(() => _loading = false);
  }

}
