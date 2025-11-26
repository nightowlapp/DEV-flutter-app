// lib/features/map/widgets/map_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb; // <-- alias
import 'package:nightowlcode/features/map/widgets/share_location_popup.dart';

// NEW: this exports showVenuePopupSheet + your draggable popup content
import 'package:nightowlcode/features/map/widgets/venue_popup.dart';

import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

import '../../../data/providers/favorite_venues/favorite_venues_provider.dart';
import '../../../data/providers/other_providers.dart';
import '../../../data/providers/map_nav_providers.dart';
import '../../../data/providers/real_time_database_providers.dart';
import '../../../data/providers/users/friends/friends_locations_provider.dart';
import '../../../data/services/location/live_location_sharing_provider.dart';
import '../../../data/services/location/location_controller.dart';
import '../../../data/providers/venues/venue_providers.dart';
import '../../../data/services/navigation/nav_tts.dart';
import '../../../data/services/navigation/navigation_service.dart';
import '../../../data/services/navigation/route_renderer.dart';
import '../../../models/navigation/nav_models.dart';
import '../../../models/users/live_location.dart';
import '../../../shared/reusable/ui/owl_scrollbar.dart';
import '../../../shared/reusable/ui/owl_snack.dart';
import '../../../shared/reusable/ui/venue_logo.dart';
import '../../../shared/utility/distance.dart';
import '../presentation/friends_fc.dart';
import '../presentation/map_logo_registry.dart';
import '../presentation/map_style.dart';
import '../presentation/initial_camera_provider.dart';
import '../presentation/map_type_icon_registry.dart';

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

  bool _navigating = false;
  NavProfile _navProfile = NavProfile.walking;
  NavRoute? _activeRoute;
  Venue? _navDest;

  StreamSubscription<geo.Position>? _posSub;
  StreamSubscription<Map<String, int>>? _liveCountsSub;
  Map<String, int>? _lastLiveCounts;

  DateTime? _lastRerouteAt;

  MapNavCommand? _pendingNav;

  final MapStyle _style = MapStyle();
  final Map<String, Venue> _venuesById = {};
  Timer? _flameTimer;
  double _flamePhase = 0.0; // 0..2π loop for the sine wave


  LatLng? _userLocation;

  // ---- navigation services
  late final NavigationService _directions;
  RouteRenderer? _renderer;
  final NavTts _tts = NavTts();

  String _logoImageIdFor(Venue v) =>
  'logo_${v.id}_${(v.updatedAt ?? v.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).millisecondsSinceEpoch}';

  bool _showClosed = true;

  Future<void> _ensureUserLocation() async {
    if (_userLocation != null) return;
    try {
      final pos = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.best,
      );
      _userLocation = LatLng(pos.latitude, pos.longitude);
    }
    catch (_) {
      // ignore – panel will just omit distances
    }
  }

  // All types we allow the user to toggle
  static const List<VenueType> _filterableTypes = [
    VenueType.bar,
    VenueType.club,
    VenueType.pub,
    VenueType.beer_bar,
    VenueType.cocktail_bar,
    VenueType.wine_bar,
    VenueType.sports_bar,
    VenueType.karaoke_bar,
    VenueType.gay_bar,
    VenueType.unknown, // TODO Actual problem Unknown should be a placeholder for venues Right now they are not a part of map. Maybe just call other at some point (if so need to check everything for lingering "unknown" around all codebases.)
  ];

  // Currently enabled types (starts with all ON)
  final Set<VenueType> _allowedTypes = Set.of(_filterableTypes);

  // Panel open/closed
  bool _filtersOpen = false;

  @override
  void initState() {
    super.initState();
    _tts.init();
    _tts.muted.addListener(() {
        if (mounted) setState(() {}
          );
      }
    );

    // 🔥 subscribe to live counts
    _liveCountsSub = liveAllVenueCounts().listen((counts) {
        // cache for later
        _lastLiveCounts = counts;

        // if the map + style are already ready, update now
        if (_map != null && _styleReady) {
          _updateHotVenuesFromCounts(counts);
        }
      }
    );

    _flameTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      final map = _map;
      if (map == null || !_styleReady) return;

      // advance phase
      _flamePhase += 0.25; // tweak speed here
      if (_flamePhase > math.pi * 2) {
        _flamePhase -= math.pi * 2;
      }

      // 0..1 pulse value
      final t = (math.sin(_flamePhase) + 1) / 2.0;

      double lerp(double a, double b, double t) => a + (b - a) * t;

      // Radii + opacities
      final outerRadius = lerp(16.0, 28.0, t);
      final innerRadius = lerp(6.0, 16.0, t);
      final outerOpacity = lerp(0.15, 0.55, t);
      final innerOpacity = lerp(0.4, 0.9, t);

      // Flame icon size (subtle pulse)
      final iconSize = lerp(16.0, 22.0, t);

      final style = map.style;

      style.setStyleLayerProperty(
        MapStyle.lyrHotGlowOuter,
        'circle-radius',
        outerRadius,
      );
      style.setStyleLayerProperty(
        MapStyle.lyrHotGlowOuter,
        'circle-opacity',
        outerOpacity,
      );

      style.setStyleLayerProperty(
        MapStyle.lyrHotGlowInner,
        'circle-radius',
        innerRadius,
      );
      style.setStyleLayerProperty(
        MapStyle.lyrHotGlowInner,
        'circle-opacity',
        innerOpacity,
      );

      style.setStyleLayerProperty(
        MapStyle.lyrHotFlameIcon,
        'text-size',
        iconSize,
      );
    });

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // safe place to read providers once in a Stateful Consumer
    _directions = ref.read(navigationServiceProvider);
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _liveCountsSub?.cancel();
    _tts.dispose();
    _flameTimer?.cancel();
    super.dispose();
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
    final map = _map;
    if (map == null) return;
    final cam = mb.CameraOptions(
      center: mb.Point(coordinates: mb.Position(location.lng, location.lat)),
      zoom: zoom,
      pitch: 0,
      bearing: 0,
    );
    map.easeTo(cam, mb.MapAnimationOptions(duration: 500));
  }

  // (kept for completeness) – now uses the pullable sheet
  Future<void> _showVenuePopupById(String id) async {
    final v = _venuesById[id];
    if (v == null || !mounted) return;

    final rootContext = Navigator.of(context, rootNavigator: true).context;
    await showVenuePopupSheet(
      rootContext,
      venue: v,
      onClose: () => Navigator.of(rootContext, rootNavigator: true).pop(),
      onGo: () async {
        Navigator.of(rootContext, rootNavigator: true).pop();
        await _buildRouteTo(v);
      },
      body: _venueDetails(v), // scrollable area content
    );
  }

  Future<void> _onMapTap(mb.MapContentGestureContext ctx) async {
    final map = _map;
    if (map == null) return;

    Map<String, dynamic>? _asMap(Object? o) => (o is Map) ? o.cast<String, dynamic>() : null;

    String? _firstId(List<mb.QueriedRenderedFeature?> items) {
      for (final r in items) {
        if (r == null) continue;
        final feat = r.queriedFeature.feature as Map?;
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

    // 3) clusters → zoom in //TODO better zoom in when clicking clusters at some point.
    final cl = await map.queryRenderedFeatures(
      box,
      mb.RenderedQueryOptions(layerIds: [MapStyle.lyrClusters]),
    );
    debugPrint('tap: cluster hits = ${cl.length}');
    for (final r in cl) {
      if (r == null) continue;
      final feat = r.queriedFeature.feature as Map?;
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

    // 4) last resort: nearest venue to the tap coordinate
    try {
      final worldPt = await map.coordinateForPixel(ctx.touchPosition);
      final pos = worldPt.coordinates as mb.Position; // (lon, lat)
      final tapLatLng = LatLng(pos.lat.toDouble(), pos.lng.toDouble());
      final nearestId = _nearestVenueId(tapLatLng, maxMeters: 60);
      if (nearestId != null) {
        debugPrint('tap -> nearest fallback id: $nearestId');
        _openVenueByIdOrExplain(nearestId);
        return;
      }
    }
    catch (_) {}

    debugPrint('tap: nothing hit');
  }

  Future<void> _centerOnUser() async {
    final cam = await ref.read(initialCameraProvider.future);
    _map?.flyTo(cam, mb.MapAnimationOptions(duration: 1200));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // All venues list, used for per-type counts and lists in the filter panel
    final allVenues = ref.watch(allVenuesListProvider);
    final favoriteIds = ref.watch(favoriteVenueIdsProvider).maybeWhen(
      data: (ids) => ids.toSet(),
      orElse: () => <String>{},
    );

    final visibleOnMapCount = _visibleVenuesOnMap(allVenues);

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
      }
    );

    ref.listen<VenuesFc>(venuesGeoJsonProvider, (prev, next) async {
        final map = _map;
        if (map == null || !_styleReady) return;

        await _style.applyFilters(
          map,
          showClosed: _showClosed,
          allowedTypes: _allowedTypeNamesForStyle(),
          baseClusterableFc: next.clusterable,
          baseVipFc: next.vip,
          favoriteVenueIds: favoriteIds,
        );

        final venues = ref.read(allVenuesListProvider);
        final idToPath2 = <String, String>{};

        for (final v in venues) {
          if (!v.isVerified) continue;

          final baseId = _logoImageIdFor(v);
          final path = 'venue_images/${v.id}/logo.webp';

          // Two CircleAvatar variants – open/closed
          idToPath2['${baseId}_open'] = path;
          idToPath2['${baseId}_closed'] = path;
        }

        final dpr = MediaQuery.of(context).devicePixelRatio.clamp(1.0, 3.0);

        await MapLogoRegistry.instance.syncIdToUrl(
          map: map,
          images: idToPath2,        // or idToPath2
          maxSize: 46,             // logical diameter on the map (same as before)
          pixelRatio: dpr.toDouble(), // e.g. 2.0 or 3.0
        );

      }
    );

    ref.listen<AsyncValue<Map<String, LiveLocation>>>(
      friendsLocationsProvider,
      (prev, next) async {
        final map = _map;
        if (map == null || !_styleReady) return;
        next.whenData((m) async {
            final fc = friendsToFeatureCollection(m);
            await _style.setFriendsData(map, fc);
          }
        );
      },
    );

    ref.listen<Map<String, Venue>>(venuesByIdMapProvider, (prev, next) {
        _venuesById
        ..clear()
        ..addAll(next);
      }
    );

    ref.listen<AsyncValue<mb.CameraOptions>>(initialCameraProvider, (prev, next) {
        next.whenData((cam) => _map?.flyTo(cam, mb.MapAnimationOptions(duration: 650)));
      }
    );

    ref.listen<AsyncValue<List<String>>>(
      favoriteVenueIdsProvider,
          (prev, next) async {
        final map = _map;
        if (map == null || !_styleReady) return;

        final ids = next.maybeWhen(
          data: (ids) => ids.toSet(),
          orElse: () => <String>{},
        );

        final fcNow = ref.read(venuesGeoJsonProvider);

        await _style.applyFilters(
          map,
          showClosed: _showClosed,
          allowedTypes: _allowedTypeNamesForStyle(),
          baseClusterableFc: fcNow.clusterable,
          baseVipFc: fcNow.vip,
          favoriteVenueIds: ids,
        );
      },
    );

    final camAsync = ref.watch(initialCameraProvider);
    final cam = camAsync.maybeWhen(data: (c) => c, orElse: () => fallbackCamera);

    final bottomOffset = _navigating ? 100.0 : 16.0; // avoids nav banner

    // Group venues per type (only the filterable ones)
    final Map<VenueType, List<Venue>> venuesByType = {
      for (final t in _filterableTypes) t: <Venue>[],
    };

    for (final v in allVenues) {
      final VenueType? t = v.type; // adjust if your field is named differently
      if (t != null && venuesByType.containsKey(t)) {
        venuesByType[t]!.add(v);
      }
    }

    // Counts per type
    final Map<VenueType, int> typeCounts = {
      for (final t in _filterableTypes) t: venuesByType[t]!.length,
    };

    // Current audience from provider
    final shareAudience = ref.watch(shareAudienceProvider);
    final sharingPosition = shareAudience != ShareAudience.none;

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
          _navBanner(),
          if (_loading)
          const Positioned.fill(
            child: ColoredBox(
              color: transparent,
            ),
          ),

          // Center on user
          Positioned(
            right: 16,
            bottom: bottomOffset,
            child: FloatingActionButton(
              heroTag: 'fab_center_user',
              mini: true,
              tooltip: 'Center on user',
              onPressed: _centerOnUser,
              child: Icon(locationIcon),
            ),
          ),

          // Filter FAB (chevron rotates when open)
          // Filter FAB (chevron rotates when open)
          // Filter FAB (chevron rotates when open + count below icon)
          Positioned(
            right: 64,
            bottom: bottomOffset,
            child: FloatingActionButton(
              mini: true,
              tooltip: 'Filter venues',
              onPressed: () async {
                await _ensureUserLocation();
                setState(() => _filtersOpen = !_filtersOpen);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedRotation(
                    turns: _filtersOpen ? 0.5 : 0.0, // 180°
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      chevronUpIcon,
                      color: white,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Text(
                      '$visibleOnMapCount',
                      key: ValueKey<int>(visibleOnMapCount),
                      style: Styles.smallText,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Share-location FAB
          Positioned(
            left: 12,
            top: 12,
            child: FloatingActionButton(
              mini: true,
              onPressed: () async {
                final currentAudience = ref.read(shareAudienceProvider);

                final selected = await showShareLocationPopup(
                  context,
                  initial: currentAudience,
                  friendsCount: 123, //TODO
                  closeFriendsCount: 21,
                );

                if (!mounted || selected == null) return;

                await ref.read(shareAudienceProvider.notifier).setAudience(selected);
              },
              child: Icon(
                sharingPosition ? distanceIcon : distanceDisabledIcon,
                color: sharingPosition ? blue : red,
              ),
            ),
          ),

          // Overlay + panel (above the FABs)
          if (_filtersOpen) ...[
            // Dark overlay for everything outside the panel.
            // Tapping it closes the panel.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _filtersOpen = false),
                child: Container(color: black.withOpacity(0.6)),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomOffset + 72, // sits above FAB row
              child: _VenueTypeFilterPanel(
                selected: _allowedTypes,
                allTypes: _filterableTypes,
                counts: typeCounts,
                venuesByType: venuesByType,
                userLocation: _userLocation,
                favoriteVenueIds: favoriteIds,

                // NEW: "Is open" toggle (true => only open venues)
                showOnlyOpen: !_showClosed,
                onShowOnlyOpenChanged: (value) async {
                  // value == true  → show only open
                  // value == false → show open + closed
                  final map = _map;
                  if (map == null || !_styleReady) return;

                  setState(() {
                      _showClosed = !value;
                    }
                  );

                  final fcNow = ref.read(venuesGeoJsonProvider);

                  await _style.applyFilters(
                    map,
                    showClosed: _showClosed,
                    allowedTypes: _allowedTypeNamesForStyle(),
                    baseClusterableFc: fcNow.clusterable,
                    baseVipFc: fcNow.vip,
                    favoriteVenueIds: favoriteIds,
                  );
                },

                onSelectionChanged: (selection) async {
                  final map = _map;
                  if (map == null || !_styleReady) return;

                  setState(() {
                      _allowedTypes
                      ..clear()
                      ..addAll(selection);
                    }
                  );

                  final fcNow = ref.read(venuesGeoJsonProvider);

                  await _style.applyFilters(
                    map,
                    showClosed: _showClosed,
                    allowedTypes: _allowedTypeNamesForStyle(),
                    baseClusterableFc: fcNow.clusterable,
                    baseVipFc: fcNow.vip,
                    favoriteVenueIds: favoriteIds,
                  );
                },

                onVenueTap: (venue) async {
                  final venueType = venue.type;
                  if (venueType == null || !_allowedTypes.contains(venueType)) {
                    _toast(
                      '${venue.displayName} is hidden. Display "${Utility.formatString(venueType!.name.replaceAll('_', ' ')) ?? 'type'}" venues on map to open it.',
                    );
                    return;
                  }
                  setState(() => _filtersOpen = false);
                  _openVenue(venue);
                },
              ),

            ),
          ],

        ],
      ),
    );
  }

  /// Map current selection to what MapStyle.applyFilters expects.
  ///
  /// - All ON  → empty set  → no type filter (show all)
  /// - All OFF → sentinel '__none__' → hide everything
  /// - Mixed   → the selected type names.
  Set<String> _allowedTypeNamesForStyle() {
    if (_allowedTypes.isEmpty) {
      // Hide everything – no venue has this type
      return {'__none__'};
    }

    if (_allowedTypes.length == _filterableTypes.length) {
      // All on → no filtering by type
      return {};
    }

    return _allowedTypes.map((e) => e.name).toSet();
  }

  Future<void> _onStyleLoaded(mb.StyleLoadedEventData _) async {
    final map = _map;
    if (map == null || _styleReady) return;

    MapLogoRegistry.instance.clear();

    await _style.ensure(map);

    // style + hot source exist now
    _styleReady = true;

    final fcNow = ref.read(venuesGeoJsonProvider);

    final favIds = ref.read(favoriteVenueIdsProvider).maybeWhen(
      data: (ids) => ids.toSet(),
      orElse: () => <String>{},
    );

    await _style.applyFilters(
      map,
      showClosed: _showClosed,
      allowedTypes: _allowedTypeNamesForStyle(),
      baseClusterableFc: fcNow.clusterable,
      baseVipFc: fcNow.vip,
      favoriteVenueIds: favIds,
    );

    final venues = ref.read(allVenuesListProvider);
    final idToPath = <String, String>{};

    for (final v in venues) {
      if (!v.isVerified) continue;

      final baseId = _logoImageIdFor(v);
      final path = 'venue_images/${v.id}/logo.webp';

      idToPath['${baseId}_open'] = path;
      idToPath['${baseId}_closed'] = path;
    }

    final dpr = MediaQuery.of(context).devicePixelRatio.clamp(1.0, 3.0);

    await MapLogoRegistry.instance.syncIdToUrl(
      map: map,
      images: idToPath,
      maxSize: 46,
      pixelRatio: dpr.toDouble(),
    );

    await MapTypeIconRegistry.instance.ensureTypeIcons(
      map: map,
      logicalSize: 24.0,
      pixelRatio: dpr.toDouble(),
    );

    // 🔥 IMPORTANT: once the style & src_hot_venues exist,
    // push in whatever counts we already saw (or empty map if none).
    final counts = _lastLiveCounts ?? const <String, int>{};
    await _updateHotVenuesFromCounts(counts);

    if (mounted) setState(() => _loading = false);

    if (_pendingNav != null) {
      final cmd = _pendingNav!;
      _pendingNav = null;
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

  Future<void> _buildRouteTo(Venue v, {NavProfile profile = NavProfile.walking}) async {
    try {
      setState(() => _loading = true);

      final pos = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.best,
      );
      final origin = LatLng(pos.latitude, pos.longitude);
      final dest = v.entry;

      final route = await _directions.route(
        origin: origin,
        destination: dest,
        profile: profile,
      );
      if (route.isEmpty) {
        _toast('No route found', variant: OwlSnackVariant.error);
        return;
      }

      _navDest = v;
      _navProfile = profile;
      _activeRoute = route;
      _navigating = true;

      await _renderer?.show(
        route,
        style: _routeStyleFor(profile),
        color: _routeColorFor(profile),
        width: 6,
      );
      await _renderer?.fitToRoute(route);

      if (route.steps.isNotEmpty) {
        await _tts.speak(route.steps.first.instruction);
      }

      // live updates
      await _posSub?.cancel();
      _posSub = geo.Geolocator.getPositionStream(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.best,
          distanceFilter: 5, // meters between ticks
        ),
      ).listen(_onLocationTick);
    }
    catch (e) {
      _toast('Routing failed: $e', variant: OwlSnackVariant.error);
    }
    finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _stopNavigation() async {
    await _posSub?.cancel();
    _posSub = null;
    _navigating = false;
    _activeRoute = null;
    _navDest = null;
    _lastRerouteAt = null;
    await _renderer?.clear();
    if (mounted) setState(() {}
      );
  }

  Future<void> _onLocationTick(geo.Position p) async {
    if (!_navigating || _navDest == null) return;

    // simple throttle to reduce API spam
    final now = DateTime.now();
    if (_lastRerouteAt != null &&
      now.difference(_lastRerouteAt!) < const Duration(seconds: 8)) {
      if (mounted) setState(() {}
        ); // still refresh banner counters
      return;
    }
    _lastRerouteAt = now;

    try {
      final origin = LatLng(p.latitude, p.longitude);
      final route = await _directions.route(
        origin: origin,
        destination: _navDest!.entry,
        profile: _navProfile,
      );
      if (route.isEmpty) return;

      _activeRoute = route;

      await _renderer?.show(
        route,
        style: _routeStyleFor(_navProfile),
        color: _routeColorFor(_navProfile),
        width: 6,
      );

      if (mounted) setState(() {}
        );
    }
    catch (_) {
      // ignore transient failures
    }
  }

  // ---- helpers ----
  void _toast(
    String msg, {
      OwlSnackVariant variant = OwlSnackVariant.neutral,
    }) {
    if (!mounted) return;

    OwlSnack.show(
      context,
      title: '',
      message: msg,
      variant: variant,
      showDivider: false,
      behavior: SnackBarBehavior.floating,
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

    final type = v.type;

    // Respect current filters Still want to open venue if displayed.
    // if (type == null || !_allowedTypes.contains(type)) {
    //   _toast('${v.displayName} is hidden by your filters.');
    //   return;
    // }

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
    await showVenuePopupSheet(
      root,
      venue: v,
      onGo: () async {
        Navigator.of(root, rootNavigator: true).pop();
        await _buildRouteTo(v);
      },
      onClose: () => Navigator.of(root, rootNavigator: true).pop(),
      body: _venueDetails(v),
    );
  }

  String? _nearestVenueId(LatLng tap, {double maxMeters = 60}) {
    final venues = ref.read(venuesByIdMapProvider);
    String? bestId;
    double best = maxMeters;

    venues.forEach((id, v) {
        final type = v.type; // VenueType?
        // Respect current type filters
        if (type == null || !_allowedTypes.contains(type)) {
          return; // skip hidden types
        }

        // Respect open/closed filter if you ever set _showClosed = false
        if (!_isVenueOpenNow(v)) return;

        final d = Distance.metersLatLng(tap, v.entry);
        if (d < best) {
          best = d;
          bestId = id;
        }
      }
    );

    return bestId;
  }

  Color _routeColorFor(NavProfile p) {
    switch (p) {
      case NavProfile.walking:
        return orange;
      case NavProfile.cycling:
        return orange;
      case NavProfile.driving:
        return orange;
    }
  }

  RouteStyle _routeStyleFor(NavProfile p) =>
  p == NavProfile.walking ? RouteStyle.line : RouteStyle.line;

  IconData _modeIcon(NavProfile p) {
    switch (p) {
      case NavProfile.walking:
        return Icons.directions_walk_rounded;
      case NavProfile.cycling:
        return Icons.directions_bike_rounded;
      case NavProfile.driving:
        return Icons.directions_car_rounded;
    }
  }

  String _fmtMeters(double meters) {
    final m = meters.round();
    if (m < 1000) return '$m m';
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
  }

  String _fmtEta(double seconds) {
    if (seconds <= 0) return '—';
    final mins = (seconds / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    return h >= 9 ? '9+ hr' : '$h hr';
  }

  String _fmtArrivalClock(BuildContext context, double seconds) {
    if (seconds <= 0) return 'now';
    final dt = DateTime.now().add(Duration(seconds: seconds.round()));
    final tod = TimeOfDay.fromDateTime(dt);

    final use24h = MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
    final loc = MaterialLocalizations.of(context);
    final clock = loc.formatTimeOfDay(tod, alwaysUse24HourFormat: use24h);

    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return clock; // today
    }
    else if (dt.difference(DateTime(now.year, now.month, now.day)).inDays == 1) {
      return clock;
    }
    else {
      return '${dt.month}/${dt.day} $clock';
    }
  }

  Widget _navBanner() {
    final r = _activeRoute;
    final dest = _navDest;
    if (!_navigating || r == null) return const SizedBox.shrink();

    final dist = _fmtMeters(r.distanceMeters);
    final travelTime = _fmtEta(r.durationSeconds);
    final eta = _fmtArrivalClock(context, r.durationSeconds);
    final step = r.steps.isNotEmpty ? r.steps.first.instruction : '';
    final destName = dest?.displayName ?? '';

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Stack(
            children: [
              Material(
                color: black,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: grey,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(_modeIcon(_navProfile),
                                color: white, size: iconSizeDefault),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _toggleMute,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: grey,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _tts.isMuted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                                color: white,
                                size: iconSizeDefault,
                              ),
                            ),
                          ),
                        ]),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(travelTime, style: Styles.basicText),
                          const SizedBox(height: 6),
                          Text(dist,
                            style: Styles.smallText
                              .copyWith(fontSize: fontSizeSmaller)),
                          const SizedBox(height: 6),
                          Text(eta,
                            style: Styles.smallText
                              .copyWith(fontSize: fontSizeSmaller)),
                        ],
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          step,
                          style: Styles.basicText,
                          textAlign: TextAlign.left,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Row(
                  children: [
                    Text('To ', style: Styles.basicText),
                    Text(
                      destName,
                      style: Styles.basicText.copyWith(color: owlPurple),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: InkWell(
                  onTap: _stopNavigation,
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(Icons.close_rounded,
                    color: greyLighter, size: iconSizeDefault),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleMute() async {
    await _tts.toggleMuted();
    if (mounted) setState(() {}
      );
  }

  // ===== scrollable content below rating/header (placeholder) =====
  Widget _venueDetails(Venue v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            alignment: Alignment.center,
            child: Text(
              'Details for ${v.displayName.isNotEmpty ? v.displayName : v.name}',
              style: Styles.basicText),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  int _visibleVenuesOnMap(List<Venue> allVenues) {
    if (_allowedTypes.isEmpty) return 0;

    int total = 0;

    for (final v in allVenues) {
      final type = v.type;
      if (type == null || !_allowedTypes.contains(type)) continue;

      // OLD:
      // if (!_showClosed && v.isOpenNow != true) continue;

      // NEW:
      if (!_showClosed && !_isVenueOpenNow(v)) continue;

      total++;
    }

    return total;
  }

  Future<void> _updateHotVenuesFromCounts(Map<String, int> counts) async {
    final map = _map;
    if (map == null || !_styleReady) return;

    final venues = ref.read(allVenuesListProvider);

    final features = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (final v in venues) {
      final visits = counts[v.id] ?? 0;
      final cap = v.capacity;

      //TODO make hot venues only animated if not in clutter. Make clutter show a perventage of hot venues within clutter (circle diagram
      final bool isHot = (cap > 0 && (visits / cap) >= 0.65); //TODO find out amount

      if (!isHot) continue;

      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [v.entry.lng, v.entry.lat],
        },
        'properties': {
          'id': v.id,
          'visits': visits,
          'capacity': cap,
        },
      });

    }

    final fc = jsonEncode({
      'type': 'FeatureCollection',
      'features': features,
    }
    );

    await _style.setHotVenuesData(map, fc);
  }




}

bool _isVenueOpenNow(Venue v) => v.isOpenNow(DateTime.now());


// ======= FILTER PANEL + EXPANDABLE TILES ===================================

// ======= FILTER PANEL + EXPANDABLE TILES ===================================

class _VenueTypeFilterPanel extends StatefulWidget {
  const _VenueTypeFilterPanel({
    required this.selected,
    required this.allTypes,
    required this.counts,
    required this.venuesByType,
    required this.userLocation,
    required this.onSelectionChanged,
    required this.onVenueTap,
    required this.showOnlyOpen,
    required this.onShowOnlyOpenChanged,
    required this.favoriteVenueIds,
  });

  final Set<VenueType> selected;
  final List<VenueType> allTypes;
  final Map<VenueType, int> counts;
  final Map<VenueType, List<Venue>> venuesByType;
  final LatLng? userLocation;
  final Set<String> favoriteVenueIds;

  final bool showOnlyOpen;
  final ValueChanged<bool> onShowOnlyOpenChanged;

  final Future<void> Function(Set<VenueType>) onSelectionChanged;
  final Future<void> Function(Venue) onVenueTap;

  @override
  State<_VenueTypeFilterPanel> createState() => _VenueTypeFilterPanelState();
}

class _VenueTypeFilterPanelState extends State<_VenueTypeFilterPanel> {
  late Set<VenueType> _selected = Set<VenueType>.from(widget.selected);

  String _labelFor(VenueType t) {
    final name = t.name.replaceAll('_', ' ');
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1);
  }

  Future<void> _updateSelection(void Function() mutate) async {
    setState(mutate);
    await widget.onSelectionChanged(Set<VenueType>.from(_selected));
  }

  /// How many venues are currently actually visible on the map,
  /// given the selected types + "Open now" toggle.
  int _visibleOnMapCount() {
    if (_selected.isEmpty) return 0;

    int total = 0;
    widget.venuesByType.forEach((type, venues) {
        if (!_selected.contains(type)) return;

        for (final v in venues) {
          if (widget.showOnlyOpen && !_isVenueOpenNow(v)) continue;
          total++;
        }
      }
    );
    return total;
  }

  Future<void> _resetFilters() async {
    // 1) Reset types to "all on"
    await _updateSelection(() {
        _selected
        ..clear()
        ..addAll(widget.allTypes);
      }
    );

    // 2) Reset "Open now" to off (show open + closed)
    if (widget.showOnlyOpen) {
      widget.onShowOnlyOpenChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = screenHeight * 0.7;
    final double outerRadius = borderRadiusDefault * 1.6;

    // Build an "effective" per-type map that already respects the
    // "Open now" toggle. When showOnlyOpen == true, we drop closed venues.
    final Map<VenueType, List<Venue>> effectiveByType = {
      for (final t in widget.allTypes) t: <Venue>[],
    };

    widget.venuesByType.forEach((type, venues) {
        final list = widget.showOnlyOpen
          ? venues.where(_isVenueOpenNow).toList()
          : List<Venue>.from(venues);
        effectiveByType[type] = list;
      }
    );

    // Counts based on the effective list (so they also respect "Open now")
    final Map<VenueType, int> effectiveCounts = {
      for (final t in widget.allTypes) t: effectiveByType[t]?.length ?? 0,
    };

    // Total venues across all types, respecting "Open now"
    final totalCount =
      effectiveCounts.values.fold<int>(0, (prev, v) => prev + v);

    // True when ALL types are currently enabled
    final allOn = _selected.length == widget.allTypes.length;

    // All venues aggregated (for the "All" expandable row),
    // already filtered by open/closed depending on showOnlyOpen.
    final List<Venue> allVenues =
      effectiveByType.values.expand((v) => v).toList();

    // Only show types that actually have (effective) venues,
    // sorted by amount desc
    final visibleTypes = widget.allTypes
      .where((t) => (effectiveCounts[t] ?? 0) > 0)
      .toList()
    ..sort((a, b) {
        final ca = effectiveCounts[a] ?? 0;
        final cb = effectiveCounts[b] ?? 0;
        if (cb != ca) return cb.compareTo(ca); // most → first
        return _labelFor(a).compareTo(_labelFor(b));
      }
    );

    final visibleOnMap = _visibleOnMapCount();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: black,
        elevation: 8,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(outerRadius),
          side: const BorderSide(color: grey, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(outerRadius),
          child: SizedBox(
            height: panelHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ===== HEADER (matches _FiltersCard) =======================
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    horizontalSpacerDefault,
                    horizontalSpacerDefault,
                    horizontalSpacerDefault,
                    horizontalSpacerSmall,
                  ),
                  child: Row(
                    children: [
                      Text('Filters', style: Styles.popupHeader),
                      const Spacer(),
                      Text('Open now', style: Styles.smallText),
                      const SizedBox(width: 6),
                      Switch.adaptive(
                        value: widget.showOnlyOpen,
                        onChanged: widget.onShowOnlyOpenChanged,
                        activeColor: owlPurple,
                        trackOutlineColor: WidgetStatePropertyAll(
                          grey.withOpacity(.5),
                        ),
                        inactiveThumbColor: grey,
                        inactiveTrackColor: grey.withOpacity(.35),
                      ),
                    ],
                  ),
                ),

                // ===== TOP CENTER INFO (replaces "Pro tip") ================
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Row(
                    key: ValueKey<int>(visibleOnMap),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$visibleOnMap ',
                        style:
                        Styles.smallText.copyWith(color: owlPurple),
                      ),
                      Text(
                        'venues shown on map',
                        style: Styles.smallText,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),
                const Divider(color: grey),

                // ===== BODY: scrollable type list ==========================
                Expanded(
                  child: OwlScrollbar(
                    child: totalCount == 0
                      ? Center( //TODO Make sadfaceOwl to show when errors/isempty
                        child: Text(
                          'No venues match your filters',
                          style: Styles.smallText
                            .copyWith(color: grey),
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: horizontalSpacerDefault,
                          vertical: verticalSpacerDefault,
                        ),
                        itemCount: 1 + visibleTypes.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: white.withOpacity(0.06),
                        ),
                        itemBuilder: (context, index) {
                          // First row = "All"
                          if (index == 0) {
                            return _VenueFilterExpandableTile(
                              label: 'All',
                              icon: Icons.all_inclusive_outlined,
                              isOn: allOn,
                              count: totalCount,
                              venues: allVenues,
                              userLocation: widget.userLocation,
                              favoriteVenueIds: widget.favoriteVenueIds,
                              // active per venue if its type is selected
                              isVenueActive: (venue) {
                                final type = venue.type;
                                if (type == null) return false;
                                if (!_selected.contains(type)) return false;
                                if (widget.showOnlyOpen && !_isVenueOpenNow(venue)) return false;
                                return true;
                              },
                              onToggleChanged: (value) {
                                _updateSelection(() {
                                    if (value) {
                                      _selected
                                      ..clear()
                                      ..addAll(widget.allTypes);
                                    }
                                    else {
                                      _selected.clear();
                                    }
                                  }
                                );
                              },
                              onVenueTap: widget.onVenueTap,
                            );
                          }

                          // Other rows = each type
                          final t = visibleTypes[index - 1];
                          final isOn = _selected.contains(t);
                          final count = effectiveCounts[t] ?? 0;
                          final venues =
                            effectiveByType[t] ?? const <Venue>[];

                          return _VenueFilterExpandableTile(
                            label: _labelFor(t) == 'Unknown' ? 'Other' : _labelFor(t),
                            icon: t.icon,
                            isOn: isOn,
                            count: count,
                            venues: venues,
                            userLocation: widget.userLocation,
                            favoriteVenueIds: widget.favoriteVenueIds,
                            onToggleChanged: (value) {
                              _updateSelection(() {
                                  if (value) {
                                    _selected.add(t);
                                  }
                                  else {
                                    _selected.remove(t);
                                  }
                                }
                              );
                            },
                            onVenueTap: widget.onVenueTap,
                          );
                        },
                      ),
                  ),
                ),

                const Divider(color: grey),

                // ===== FOOTER: Reset Filters (both sides) =================
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    horizontalSpacerDefault,
                    horizontalSpacerSmall,
                    horizontalSpacerDefault,
                    horizontalSpacerSmall,
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          _resetFilters();
                        },
                        child: Text(
                          'Reset Filters',
                          style: Styles.smallText
                            .copyWith(color: red),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _resetFilters();
                        },
                        child: Text(
                          'Reset Filters',
                          style: Styles.smallText
                            .copyWith(color: red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VenueFilterExpandableTile extends StatefulWidget {
  const _VenueFilterExpandableTile({
    required this.label,
    required this.icon,
    required this.isOn,
    required this.count,
    required this.venues,
    required this.userLocation,
    required this.onToggleChanged,
    required this.onVenueTap,
    required this.favoriteVenueIds,
    this.isVenueActive,
  });

  final String label;
  final IconData icon;
  final bool isOn;
  final int count;
  final List<Venue> venues;
  final LatLng? userLocation;
  final ValueChanged<bool> onToggleChanged;
  final Future<void> Function(Venue) onVenueTap;
  final Set<String> favoriteVenueIds;

  /// Optional per-venue active check (used by "All" row).
  /// If null, `isOn` is used for all venues in this tile.
  final bool Function(Venue v)? isVenueActive;

  @override
  State<_VenueFilterExpandableTile> createState() =>
  _VenueFilterExpandableTileState();
}


class _VenueFilterExpandableTileState extends State<_VenueFilterExpandableTile> {
  bool _expanded = false;

  // Pagination: how many venues we currently show in this tile.
  static const int _pageSize = 48;
  int _visibleCount = _pageSize;

  // Scroll controller for the inner dropdown list
  late final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
        _expanded = !_expanded;
        if (_expanded) {
          // Reset page + scroll back to top when opening
          _visibleCount = _pageSize;
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        }
      }
    );
  }

  // Auto "show more" when scrolled to the bottom
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;

    // Small tolerance so it still triggers if you're *almost* at the bottom
    const double tolerance = 16.0;

    if (pos.pixels >= pos.maxScrollExtent - tolerance) {
      _maybeLoadMore();
    }
  }

  void _maybeLoadMore() {
    final total = widget.venues.length;
    if (_visibleCount >= total) return; // nothing more to load

    setState(() {
        _visibleCount = math.min(_visibleCount + _pageSize, total);
      }
    );
  }

  List<Venue> _sortedVenues() {
    final list = List<Venue>.from(widget.venues);
    final user = widget.userLocation;
    if (user == null) return list;

    list.sort((a, b) {
        final da = Distance.metersLatLng(user, a.entry);
        final db = Distance.metersLatLng(user, b.entry);
        return da.compareTo(db);
      }
    );
    return list;
  }

  String _fmtMeters(double meters) {
    final m = meters.round();

    // Under 1 km → show meters
    if (m < 1000) return '$m m';

    final km = meters / 1000.0;

    // Over 99 km → cap label
    if (km > 99) return '99+ km';

    // Otherwise: 0–9.9 → 1 decimal, 10–99 → no decimals
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final venues = _sortedVenues();
    final bool headerActive = widget.isOn;

    // Clamp visible count so we never go out of range.
    final int visible = math.min(_visibleCount, venues.length);
    final List<Venue> visibleVenues = venues.take(visible).toList();
    final int remaining = venues.length - visible; // still used for sizing

    final TextStyle headerLabelStyle = headerActive
      ? Styles.basicText
      : Styles.basicText.copyWith(color: greyLighter);

    return Column(
      children: [
        // ===== HEADER ROW (ENTIRE ROW CLICKABLE) =======================
        InkWell(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          onTap: _toggleExpanded,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                // Icon circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: headerActive
                      ? owlPurple.withOpacity(0.18)
                      : white.withOpacity(0.04),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    widget.icon,
                    color: headerActive ? owlPurple : greyLighter,
                    size: iconSizeSmall,
                  ),
                ),
                const SizedBox(width: 12),

                // Label
                Expanded(
                  child: Text(
                    widget.label,
                    style: headerLabelStyle,
                  ),
                ),

                // Count
                if (widget.count > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${widget.count})',
                    style: Styles.smallText.copyWith(color: greyLighter),
                  ),
                ],

                const SizedBox(width: 8),

                // Toggle (still only toggles filter, not expansion)
                Switch.adaptive(
                  value: widget.isOn,
                  onChanged: widget.onToggleChanged,
                  activeColor: owlPurple,
                  activeTrackColor: owlPurple.withOpacity(0.4),
                  inactiveThumbColor: grey,
                  inactiveTrackColor: white.withOpacity(0.12),
                ),

                const SizedBox(width: 4),

                // Chevron (purely visual now – row InkWell handles tap)
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    chevronUpIcon,
                    color: white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ===== EXPANDED CONTENT ========================================
        if (_expanded && venues.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Max height for the inner scroll area
              const double maxInnerHeight = 260.0;

              // Estimate a row height so the list doesn't get taller than needed
              const double rowHeight = 52.0;
              final int visible = visibleVenues.length;

              // We still use `remaining` only to approximate needed height,
              // but there is no "Show more" row any more.
              final double neededHeight =
                visible * rowHeight + (remaining > 0 ? 8.0 : 0.0);

              final double height = math.min(
                maxInnerHeight,
                neededHeight,
              );

              return SizedBox(
                height: height,
                child: OwlScrollbar(
                  thickness: 1,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(right: 3), // space for scrollbar
                    itemCount: visibleVenues.length,
                    itemBuilder: (context, index) {
                      final v = visibleVenues[index];
                      return _buildVenueRow(context, v);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVenueRow(BuildContext context, Venue v) {
    final user = widget.userLocation;
    final now = DateTime.now();

    final name = v.displayName.isNotEmpty ? v.displayName : v.name;

// Active under current filters? (used by "All" tile)
    final bool venueActive = widget.isVenueActive?.call(v) ?? widget.isOn;

// Is this venue one of my favorites?
    final bool isFavorite = widget.favoriteVenueIds.contains(v.id);

    TextStyle nameStyle;
    if (!venueActive) {
      // Dim everything that’s filtered out, even favorites
      nameStyle = Styles.basicText.copyWith(color: greyLighter);
    } else if (isFavorite) {
      // Highlight favorites in owlPurple
      nameStyle = Styles.basicText.copyWith(color: owlPurple);
    } else {
      nameStyle = Styles.basicText;
    }


    final TextStyle walkStyle = Styles.smallText.copyWith(
      color: white, // ⬅️ walk text should be white
      fontSize: fontSizeSmaller,
    );

    // Walking distance text like "🚶 5 min"
    final String walk = Distance.walkText(user, v);
    final String dist = Distance.normalDistanceText(user, v);
    final String? walkLabel = walk.isEmpty && dist.isEmpty ? null : '$walk - $dist';

    // Opening-hours display info (range + +1 flag)
    final _OpeningDisplayRow opening = _openingDisplayForVenue(v, now);

    // Age restriction, e.g. "21+"
    final String? ageLabel = _ageRestrictionLabelFor(v, now);

    // Right side top: only the time range, or nothing.
    Widget openingTop;
    if (opening.showRange) {
      // Show "HH:mm - HH:mm" with "+1" as superscript when nextDay = true.
      // Always white text.
      final baseStyle = Styles.smallText.copyWith(
        color: white,
        fontSize: fontSizeSmaller,
      );
      final supStyle = Styles.smallText.copyWith(
        fontSize: 6,
      );

      openingTop = Align(
        alignment: Alignment.centerRight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              '${opening.open} - ${opening.close}',
              style: baseStyle,
              overflow: TextOverflow.ellipsis,
            ),
            if (opening.nextDay)
            Positioned(
              right: -2,
              top: -5,
              child: Text(
                '+1',
                style: supStyle,
              ),
            ),
          ],
        ),
      );
    }
    else {
      // Closed today (or only opens tomorrow) → show nothing
      openingTop = const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => widget.onVenueTap(v),
      borderRadius: BorderRadius.circular(borderRadiusSmall),
      child: Padding(
        // slightly larger vertically
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ===== LEFT: logo ============================================
            VenueLogo(
              venue: v,
              size: iconSizeLarge + 4,
            ),
            const SizedBox(width: 8),

            // ===== CENTER: name (top) + walk text (bottom) ===============
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name (one line, ellipsis)
                  Text( //TODO display star before name if favorite. Show at top if favorite.
                    name,
                    style: nameStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Walk text (white)
                  if (walkLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      walkLabel,
                      style: walkStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ===== RIGHT: opening hours (top) + age (bottom) =============
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Top: only "HH:mm - HH:mm (+1)" or nothing
                openingTop,

                const SizedBox(height: 4),

                // Bottom: age restriction e.g. "21+"
                if (ageLabel != null)
                Text(
                  ageLabel,
                  style: Styles.smallText.copyWith(
                    color: venueActive ? white : greyLighter,
                    fontSize: fontSizeSmaller,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

/// Data needed to render the right-side opening-hours block.
class _OpeningDisplayRow {
  final bool showRange;  // true => show "HH:mm - HH:mm" (+1)
  final String open;     // "HH:mm"
  final String close;    // "HH:mm"
  final bool nextDay;    // close is next day → show "+1"

  const _OpeningDisplayRow({
    required this.showRange,
    required this.open,
    required this.close,
    required this.nextDay,
  });
}

/// Compute what to show on the right side: time range + "+1" flag.
///
/// Rules:
/// - If closed today  → showRange = false (nothing rendered)
/// - If open now      → show today's full hours
/// - If opens later today → show today's full hours
/// - No "open/close" words, only "HH:mm - HH:mm" (+1)
_OpeningDisplayRow _openingDisplayForVenue(Venue v, DateTime nowLocal) {
  final now = nowLocal.toLocal();

  // Structured status (open / opens later today / opens tomorrow / closed today)
  final status = v.openingHours.statusAt(now);

  // "Today" range (with overnight support + nextDay flag)
  // Uses your Venue extension from venue.dart
  final range = v.openingHoursToday(venueLocalNow: now);
  final bool hasRange = !range.isClosed;

  // Show times only when:
  //  - currently open, OR
  //  - it opens later today.
  //
  // If closed all day or only opens tomorrow → show nothing.
  final bool showRange =
    hasRange &&
      (status.phase == OpeningPhase.open ||
        status.phase == OpeningPhase.opensLaterToday);

  if (!showRange) {
    return const _OpeningDisplayRow(
      showRange: false,
      open: '',
      close: '',
      nextDay: false,
    );
  }

  return _OpeningDisplayRow(
    showRange: true,
    open: range.open,
    close: range.close,
    nextDay: range.nextDay,
  );
}


/// Age restriction label for *today/now*, e.g. "21+"
String? _ageRestrictionLabelFor(Venue v, DateTime nowLocal) {
  final age = v.effectiveAgeRestriction(nowLocal.toLocal());
  if (age <= 0) return null;
  return '$age+';
}


/// Simple struct for an opening-hours label in the filter dropdown.
class _OpeningStatusInfo {
  final String text;
  final Color color;
  final bool shouldShow;

  _OpeningStatusInfo({
    required this.text,
    this.color = white,
    this.shouldShow = true,
  });
}

/// Compute a short opening-status label (open / opens soon / closes soon).
///
/// TODO: Wire this into your real opening-hours logic:
///  - is open now
///  - opens within 60 minutes
///  - closes within 60 minutes
_OpeningStatusInfo _openingStatusInfoFor(Venue v) {
  final now = DateTime.now(); // ideally venue-local
  final status = v.openingHours.statusAt(now);
  final label = status.label(localNow: now, soonThresholdMinutes: 60);

  // Only show something if:
  //  - venue is open now
  //  - OR opens soon
  //  - OR closes soon
  final phase = status.phase;

  final bool isOpenNow = phase == OpeningPhase.open;

  // We can infer "soon" from the label we generated above:
  final bool isSoon =
    label.startsWith('Opens in') || label.startsWith('Closes in');

  final bool shouldShow = isOpenNow || isSoon;

  if (!shouldShow) {
    return _OpeningStatusInfo(
      text: '',
      color: grey,
    );
  }

  return _OpeningStatusInfo(
    text: label,
    color: label.startsWith('Closes in') ? orange : owlPurple,
    shouldShow: true,
  );
}

