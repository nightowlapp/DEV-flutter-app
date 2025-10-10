// lib/features/map/widgets/map_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb; // <-- alias
import 'package:nightowlcode/features/map/widgets/venue_popup.dart';

import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

import '../../../data/providers/other_providers.dart';
import '../../../data/providers/map_nav_providers.dart';
import '../../../data/providers/users/friends_locations_provider.dart';
import '../../../data/services/location/location_controller.dart';
import '../../../data/providers/venues/venue_providers.dart';
import '../../../data/services/navigation/nav_tts.dart';
import '../../../data/services/navigation/navigation_service.dart';
import '../../../data/services/navigation/route_renderer.dart';
import '../../../models/users/live_location.dart';
import '../../../shared/utility/distance.dart';
import '../presentation/friends_fc.dart';
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
  mb.MapboxMap? _map;
  bool _mapCreated = false;
  bool _loading = true;
  bool _styleReady = false;
  int _lastNavId = 0;

  MapNavCommand? _pendingNav;

  final MapStyle _style = MapStyle();
  final Map<String, Venue> _venuesById = {};

  // ---- navigation services
  late final NavigationService  _directions;
  RouteRenderer? _renderer;
  final NavTts _tts = NavTts();

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
  void initState() {
    super.initState();
    _tts.init(); // default en-US
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // safe place to read providers once in a Stateful Consumer
    _directions = ref.read(navigationServiceProvider);
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _onMapCreated(mb.MapboxMap map) async {
    if (_mapCreated) return;
    _map = map;
    _mapCreated = true;

    await _map!.location.updateSettings(
      mb.LocationComponentSettings(
        enabled: true,
        accuracyRingColor: blue.value,
        accuracyRingBorderColor: white.value,
        showAccuracyRing: true,
      ),
    );
    await _map!.scaleBar.updateSettings(
      mb.ScaleBarSettings(enabled: false, isMetricUnits: true),
    );
    await _map!.attribution.updateSettings(
      mb.AttributionSettings(clickable: false, iconColor: transparent.toARGB32()),
    );
    await _map!.compass.updateSettings(
      mb.CompassSettings(marginTop: 12.0, marginRight: 12.0),
    );

    _renderer = await RouteRenderer.attach(map);
  }

  // fly helper (uses Mapbox Position, not geolocator Position)
  Future<void> _navigateTo(LatLng location, {double zoom = 16}) async {
    final map = _map; if (map == null) return;
    final cam = mb.CameraOptions(
      center: mb.Point(coordinates: mb.Position(location.lng, location.lat)),
      zoom: zoom,
      pitch: 0,
      bearing: 0,
    );
    map.easeTo(cam, mb.MapAnimationOptions(duration: 500));
  }

  Future<void> _showVenuePopupById(String id) async {
    final v = _venuesById[id];
    if (v == null || !mounted) return;

    final rootContext = Navigator.of(context, rootNavigator: true).context;
    await showModalBottomSheet(
      context: rootContext,
      useRootNavigator: true,
      backgroundColor: black,
      isScrollControlled: false,
      builder: (_) => VenuePopup(
        venue: v,
        onClose: () => Navigator.of(rootContext, rootNavigator: true).pop(),
        onOpenDetails: () {},
        onGo: () async {
          Navigator.of(rootContext, rootNavigator: true).pop();
          await _buildRouteTo(v);
        },
      ),
    );
  }

  void _openVenueById(String id) async {
    final v = _venuesById[id];
    if (v == null) return;
    _navigateTo(v.entry);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await _showVenuePopupById(id);
  }

  Future<void> _onMapTap(mb.MapContentGestureContext ctx) async {
    debugPrint('🟣 map tap at screen=(${ctx.touchPosition.x}, ${ctx.touchPosition.y})');

    final map = _map; if (map == null) return;

    Map<String, dynamic>? _asMap(Object? o) => (o is Map) ? o.cast<String, dynamic>() : null;

    String? _firstId(List<mb.QueriedRenderedFeature?> items) {
      for (final r in items) {
        if (r == null) continue;
        final feat  = r.queriedFeature.feature as Map?;
        final props = _asMap(feat?['properties']);
        final rawId = props?['id'] ?? props?['venue_id'] ?? props?['venueId'] ?? feat?['id'];
        if (rawId != null) return rawId.toString();
      }
      return null;
    }

    // use a slightly larger box: 44x44 px target-ish
    const half = 22.0;
    final p = ctx.touchPosition;
    final box = mb.RenderedQueryGeometry.fromScreenBox(
      mb.ScreenBox(
        min: mb.ScreenCoordinate(x: p.x - half, y: p.y - half),
        max: mb.ScreenCoordinate(x: p.x + half, y: p.y + half),
      ),
    );

    // 1) symbols (VIP + regular) + their labels (you might be tapping text)
    final sym = await map.queryRenderedFeatures(
      box,
      mb.RenderedQueryOptions(layerIds: [
        MapStyle.lyrVip,
        MapStyle.lyrUnclustered,
        MapStyle.lyrVipLabels,
        MapStyle.lyrLabels,
      ]),
    );
    debugPrint('tap: symbol/labels hits = ${sym.length}');
    final symId = _firstId(sym);
    if (symId != null) {
      debugPrint('tap -> id: $symId');
      _openVenueByIdOrExplain(symId);
      return;
    }

    // 2) background dots
    final dots = await map.queryRenderedFeatures(
      box,
      mb.RenderedQueryOptions(layerIds: [MapStyle.lyrVipBg, MapStyle.lyrUnclusteredBg]),
    );
    debugPrint('tap: bg hits = ${dots.length}');
    final dotId = _firstId(dots);
    if (dotId != null) {
      debugPrint('tap -> bg id: $dotId');
      _openVenueByIdOrExplain(dotId);
      return;
    }

    // 3) clusters → zoom in
    final cl = await map.queryRenderedFeatures(
      box,
      mb.RenderedQueryOptions(layerIds: [MapStyle.lyrClusters]),
    );
    debugPrint('tap: cluster hits = ${cl.length}');
    for (final r in cl) {
      if (r == null) continue;
      final feat  = r.queriedFeature.feature as Map?;
      final props = _asMap(feat?['properties']);
      if (props?['point_count'] != null) {
        final coords = (_asMap(feat?['geometry'])?['coordinates'] as List?)?.cast<num>();
        if (coords != null && coords.length >= 2) {
          final lon = coords[0].toDouble(), lat = coords[1].toDouble();
          final cs = await map.getCameraState();
          map.easeTo(
            mb.CameraOptions(
              center: mb.Point(coordinates: mb.Position(lon, lat)),
              zoom: (cs.zoom + 1.6).clamp(3.0, 20.0),
            ),
            mb.MapAnimationOptions(duration: 500),
          );
        }
        return;
      }
    }

    // 4) last resort: find nearest venue to the tap coordinate (useful if feature lacks id)
    try {
      final worldPt = await map.coordinateForPixel(ctx.touchPosition);
      final pos = worldPt.coordinates as mb.Position; // (lon, lat)
      final tapLatLng = LatLng(pos.lat.toDouble(), pos.lng.toDouble());
      final nearestId = _nearestVenueId(tapLatLng, maxMeters: 60); // small radius
      if (nearestId != null) {
        debugPrint('tap -> nearest fallback id: $nearestId');
        _openVenueByIdOrExplain(nearestId);
        return;
      }
    } catch (_) {}

    debugPrint('tap: nothing hit');
  }

  Future<void> _centerOnUser() async {
    final cam = await ref.read(initialCameraProvider.future);
    _map?.flyTo(cam, mb.MapAnimationOptions(duration: 1200));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.listen<MapNavCommand?>(mapNavControllerProvider, (prev, next) async {
      final map = _map;
      if (next == null || next.id <= _lastNavId) return;
      _lastNavId = next.id;

      if (map == null || !_styleReady) {
        _pendingNav = next;
        return;
      }
      map.easeTo(
        mb.CameraOptions(
          center: mb.Point(coordinates: mb.Position(next.target.lng, next.target.lat)),
          zoom: next.zoom,
        ),
        mb.MapAnimationOptions(duration: 500),
      );
    });

    ref.listen<VenuesFc>(venuesGeoJsonProvider, (prev, next) async {
      final map = _map; if (map == null || !_styleReady) return;
      await _style.setVenueData(map, clusterableFc: next.clusterable, vipFc: next.vip);

      final venues = ref.read(venuesListProvider);
      final idToPath2 = <String, String>{};
      for (final v in venues) {
        if (v.isVerified) {
          final id = _logoImageIdFor(v);
          idToPath2[id] = 'venue_images/${v.id}/logo.webp';
        }
      }
      await MapLogoRegistry.instance.syncIdToUrl(map: map, images: idToPath2);
    });

    ref.listen<AsyncValue<Map<String, LiveLocation>>>(
      friendsLocationsProvider,
          (prev, next) async {
        final map = _map; if (map == null || !_styleReady) return;
        next.whenData((m) async {
          final fc = friendsToFeatureCollection(m);
          await _style.setFriendsData(map, fc);
        });
      },
    );

    ref.listen<Map<String, Venue>>(venuesByIdMapProvider, (prev, next) {
      _venuesById..clear()..addAll(next);
    });

    ref.listen<AsyncValue<mb.CameraOptions>>(initialCameraProvider, (prev, next) {
      next.whenData((cam) => _map?.flyTo(cam, mb.MapAnimationOptions(duration: 650)));
    });

    final camAsync = ref.watch(initialCameraProvider);
    final cam = camAsync.maybeWhen(data: (c) => c, orElse: () => fallbackCamera);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          mb.MapWidget(
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

  Future<void> _onStyleLoaded(mb.StyleLoadedEventData _) async {
    final map = _map; if (map == null || _styleReady) return;
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

    final venues = ref.read(venuesListProvider);
    final idToPath = <String, String>{};
    for (final v in venues) {
      if (!v.isVerified) continue;
      final id = _logoImageIdFor(v);
      idToPath[id] = 'venue_images/${v.id}/logo.webp';
    }
    await MapLogoRegistry.instance.syncIdToUrl(map: map, images: idToPath);

    if (mounted) setState(() => _loading = false);

    if (_pendingNav != null) {
      final cmd = _pendingNav!; _pendingNav = null;
      map.easeTo(
        mb.CameraOptions(
          center: mb.Point(coordinates: mb.Position(cmd.target.lng, cmd.target.lat)),
          zoom: cmd.zoom,
        ),
        mb.MapAnimationOptions(duration: 500),
      );
    }
  }

  // ---------------- ROUTING ----------------

  Future<void> _buildRouteTo(Venue v) async {
    try {
      setState(() => _loading = true);

      // 1) current user position
      final pos = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.best,
      );
      final origin = LatLng(pos.latitude, pos.longitude);
      final dest = v.entry;

      // 2) fetch route via service
      final route = await _directions.walkingRoute(origin: origin,destination: dest,);
      if (route.isEmpty) {
        _toast('No route found');
        return;
      }

      // 3) draw and fit
      await _renderer?.show(route);
      await _renderer?.fitToRoute(route);

      // 4) (optional) speak first step
      if (route.steps.isNotEmpty) {
        await _tts.speak(route.steps.first.instruction);
      }

      _toast('Route ready: ${route.distanceMeters.round()} m, '
          '${(route.durationSeconds / 60).round()} min');
    } catch (e) {
      _toast('Routing failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---- helpers ----
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _openVenueByIdOrExplain(String id) {
    final venues = ref.read(venuesByIdMapProvider);
    final v = venues[id];
    if (v == null) {
      debugPrint('tap: id "$id" not found (map has ${venues.length} items).');
      _toast('Loading venue… try again in a sec');
      return;
    }
    _openVenue(v);
  }

  void _openVenue(Venue v) async {
    await _navigateTo(v.entry);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await _showVenuePopup(v); // pass the venue directly
  }

  Future<void> _showVenuePopup(Venue v) async {
    final root = Navigator.of(context, rootNavigator: true).context;
    await showModalBottomSheet(
      context: root,
      useRootNavigator: true,
      backgroundColor: black,
      builder: (_) => VenuePopup(
        venue: v,
        onClose: () => Navigator.of(root, rootNavigator: true).pop(),
        onOpenDetails: () {},
        onGo: () async {
          Navigator.of(root, rootNavigator: true).pop();
          await _buildRouteTo(v);
        },
      ),
    );
  }

  String? _nearestVenueId(LatLng tap, {double maxMeters = 60}) {
    final venues = ref.read(venuesByIdMapProvider);
    String? bestId;
    double best = maxMeters;
    venues.forEach((id, v) {
      final d = Distance.metersLatLng(tap, v.entry);
      if (d < best) { best = d; bestId = id; }
    });
    return bestId;
  }

}
