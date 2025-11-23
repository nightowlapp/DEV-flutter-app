// lib/features/map/widgets/map_screen.dart
import 'dart:async';
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

import '../../../data/providers/other_providers.dart';
import '../../../data/providers/map_nav_providers.dart';
import '../../../data/providers/users/friends/friends_locations_provider.dart';
import '../../../data/services/location/live_location_sharing_provider.dart';
import '../../../data/services/location/location_controller.dart';
import '../../../data/providers/venues/venue_providers.dart';
import '../../../data/services/navigation/nav_tts.dart';
import '../../../data/services/navigation/navigation_service.dart';
import '../../../data/services/navigation/route_renderer.dart';
import '../../../models/navigation/nav_models.dart';
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

  bool _navigating = false;
  NavProfile _navProfile = NavProfile.walking;
  NavRoute? _activeRoute;
  Venue? _navDest;

  StreamSubscription<geo.Position>? _posSub;
  DateTime? _lastRerouteAt;

  MapNavCommand? _pendingNav;

  final MapStyle _style = MapStyle();
  final Map<String, Venue> _venuesById = {};

  LatLng? _userLocation;

  // ---- navigation services
  late final NavigationService _directions;
  RouteRenderer? _renderer;
  final NavTts _tts = NavTts();

  String _logoImageIdFor(Venue v) =>
      'logo_${v.id}_${(v.updatedAt ?? v.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).millisecondsSinceEpoch}';

  final bool _showClosed = true;

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
  ];

  // Currently enabled types (starts with all ON)
  final Set<VenueType> _allowedTypes = Set.of(_filterableTypes);

  // Panel open/closed
  bool _filtersOpen = false;

  @override
  void initState() {
    super.initState();
    _tts.init(); // default en-US
    _tts.muted.addListener(() {
      if (mounted) setState(() {}
      );
    }
    );
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
    _tts.dispose();
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

    // 3) clusters → zoom in
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
      );

      final venues = ref.read(allVenuesListProvider);
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

    final camAsync = ref.watch(initialCameraProvider);
    final cam = camAsync.maybeWhen(data: (c) => c, orElse: () => fallbackCamera);

    final bottomOffset = _navigating ? 100.0 : 16.0; // avoids nav banner

    // All venues list, used for per-type counts and lists in the filter panel
    final allVenues = ref.watch(allVenuesListProvider);

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
              child: AnimatedRotation(
                turns: _filtersOpen ? 0.5 : 0.0, // 180°
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  chevronUpIcon,
                  color: white,
                ),
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
                onSelectionChanged: (selection) async {
                  final map = _map;
                  if (map == null || !_styleReady) return;

                  setState(() {
                    _allowedTypes
                      ..clear()
                      ..addAll(selection);
                  });

                  final fcNow = ref.read(venuesGeoJsonProvider);

                  await _style.applyFilters(
                    map,
                    showClosed: _showClosed,
                    allowedTypes: _allowedTypeNamesForStyle(),
                    baseClusterableFc: fcNow.clusterable,
                    baseVipFc: fcNow.vip,
                  );
                },
                onVenueTap: (venue) async {
                  // If this venue's type is currently filtered OUT, do nothing (or show a toast).
                  final venueType = venue.type; // assuming Venue.type is VenueType?
                  if (venueType == null || !_allowedTypes.contains(venueType)) {
                    _toast(
                      'This venue is hidden. Enable the "${venueType?.name.replaceAll('_', ' ') ?? 'type'}" filter to open it.',
                    );
                    return;
                  }

                  // Only if it's visible according to current filters:
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
    _styleReady = true;

    MapLogoRegistry.instance.clear();

    await _style.ensure(map);

    final fcNow = ref.read(venuesGeoJsonProvider);

    await _style.applyFilters(
      map,
      showClosed: _showClosed,
      allowedTypes: _allowedTypeNamesForStyle(),
      baseClusterableFc: fcNow.clusterable,
      baseVipFc: fcNow.vip,
    );

    final venues = ref.read(allVenuesListProvider);
    final idToPath = <String, String>{};
    for (final v in venues) {
      if (!v.isVerified) continue;
      final id = _logoImageIdFor(v);
      idToPath[id] = 'venue_images/${v.id}/logo.webp';
    }
    await MapLogoRegistry.instance.syncIdToUrl(map: map, images: idToPath);

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
        _toast('No route found');
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
      _toast('Routing failed: $e');
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

    final type = v.type;

    // Respect current filters
    if (type == null || !_allowedTypes.contains(type)) {
      _toast('This venue is hidden by your filters.');
      return;
    }

    if (!_showClosed) {
      final isOpen = v.isOpenNow == true; // again, adjust field name if needed
      if (!isOpen) {
        _toast('This venue is hidden because it’s closed.');
        return;
      }
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
      if (!_showClosed) {
        final isOpen = v.isOpenNow == true; // adjust field name if needed
        if (!isOpen) return;
      }

      final d = Distance.metersLatLng(tap, v.entry);
      if (d < best) {
        best = d;
        bestId = id;
      }
    });

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
}

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
  });

  final Set<VenueType> selected;
  final List<VenueType> allTypes;
  final Map<VenueType, int> counts;
  final Map<VenueType, List<Venue>> venuesByType;
  final LatLng? userLocation;
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

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.7;

    // Total venues across all filterable types
    final totalCount =
    widget.counts.values.fold<int>(0, (prev, v) => prev + v);

    // True when ALL types are currently enabled
    final allOn = _selected.length == widget.allTypes.length;

    // Only show types that actually have venues, sorted by amount desc
    final visibleTypes = widget.allTypes
        .where((t) => (widget.counts[t] ?? 0) > 0)
        .toList()
      ..sort((a, b) {
        final ca = widget.counts[a] ?? 0;
        final cb = widget.counts[b] ?? 0;
        if (cb != ca) return cb.compareTo(ca); // most → first
        return _labelFor(a).compareTo(_labelFor(b));
      }
      );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: black,
        borderRadius: BorderRadius.circular(borderRadiusDefault),
        elevation: 12,
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              const SizedBox(height: 8),
              // drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: grey,
                  borderRadius: BorderRadius.circular(borderRadiusSmallest),
                ),
              ),

              // Header: title + total count + global toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('Venues on map', style: Styles.basicTextHeader),
                    const Spacer(),

                    //TODO switch this out with is open filter.


                  ],
                ),
              ),

              Divider(color: grey),
              Row(
                children: [
                  if (totalCount > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '($totalCount)',
                      style: Styles.smallText.copyWith(color: greyLighter),
                    ),
                  ],
                  Switch.adaptive(
                    value: allOn,
                    onChanged: (value) {
                      _updateSelection(() {
                        if (value) {
                          _selected
                            ..clear()
                            ..addAll(widget.allTypes);
                        } else {
                          _selected.clear();
                        }
                      });
                    },
                    activeColor: owlPurple,
                    activeTrackColor: owlPurple.withOpacity(0.4),
                    inactiveThumbColor: grey,
                    inactiveTrackColor: white.withOpacity(0.12),
                  ),
                ],
              ),
              // Per-type expandable toggles with counts (sorted by count)
              Expanded(
                child: visibleTypes.isEmpty
                    ? Center(
                  child: Text(
                    'No venues found',
                    style: Styles.smallText.copyWith(color: greyLighter),
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: visibleTypes.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: white.withOpacity(0.06),
                  ),
                  itemBuilder: (context, index) {
                    final t = visibleTypes[index];
                    final isOn = _selected.contains(t);
                    final count = widget.counts[t] ?? 0;
                    final venues = widget.venuesByType[t] ?? const <Venue>[];

                    return _VenueTypeExpandableTile(
                      label: _labelFor(t),
                      type: t,
                      isOn: isOn,
                      count: count,
                      venues: venues,
                      userLocation: widget.userLocation,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueTypeExpandableTile extends StatefulWidget {
  const _VenueTypeExpandableTile({
    required this.label,
    required this.type,
    required this.isOn,
    required this.count,
    required this.venues,
    required this.userLocation,
    required this.onToggleChanged,
    required this.onVenueTap,
  });

  final String label;
  final VenueType type;
  final bool isOn;
  final int count;
  final List<Venue> venues;
  final LatLng? userLocation;
  final ValueChanged<bool> onToggleChanged;
  final Future<void> Function(Venue) onVenueTap;

  @override
  State<_VenueTypeExpandableTile> createState() =>
      _VenueTypeExpandableTileState();
}

class _VenueTypeExpandableTileState extends State<_VenueTypeExpandableTile> {
  bool _expanded = false;

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
    if (m < 1000) return '$m m';
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final venues = _sortedVenues();

    return Column(
      children: [
        // Top row: icon, label, count, toggle, dropdown chevron
        Row(
          children: [
            // Icon circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.isOn
                    ? owlPurple.withOpacity(0.18)
                    : white.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                widget.type.icon,
                color: widget.isOn ? owlPurple : greyLighter,
                size: iconSizeSmall,
              ),
            ),
            const SizedBox(width: 12),

            // Label
            Expanded(
              child: Text(
                widget.label,
                style: Styles.basicText,
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

            // Toggle
            Switch.adaptive(
              value: widget.isOn,
              onChanged: widget.onToggleChanged,
              activeColor: owlPurple,
              activeTrackColor: owlPurple.withOpacity(0.4),
              inactiveThumbColor: grey,
              inactiveTrackColor: white.withOpacity(0.12),
            ),

            // Dropdown chevron (RIGHT of toggle)
            IconButton(
              iconSize: 20,
              splashRadius: 20,
              onPressed: () {
                setState(() => _expanded = !_expanded);
              },
              icon: AnimatedRotation(
                turns: _expanded ? 0.5 : 0.0, // 180°
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  chevronUpIcon,
                  color: white,
                  size: 18,
                ),
              ),
            ),

          ],
        ),

        // Expanded list of venues of this type, sorted by distance
        if (_expanded && venues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 44, top: 4, bottom: 4),
            child: Column(
              children: venues.map((v) {
                final user = widget.userLocation;
                String? distanceLabel;
                if (user != null) {
                  final d = Distance.metersLatLng(user, v.entry);
                  distanceLabel = _fmtMeters(d);
                }

                final name =
                (v.displayName.isNotEmpty ? v.displayName : v.name);

                return InkWell(
                  onTap: widget.isOn ? () => widget.onVenueTap(v) : null,
                  borderRadius: BorderRadius.circular(borderRadiusSmall),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: Styles.smallText.copyWith(
                              color: widget.isOn ? white : grey, // optional visual hint
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (distanceLabel != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            distanceLabel,
                            style: Styles.smallText.copyWith(
                              color: widget.isOn ? owlPurple : grey, // optional
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );

              }
              ).toList(),
            ),
          ),
      ],
    );
  }
}



class _VenueTypeToggleTile extends StatelessWidget {
  const _VenueTypeToggleTile({
    required this.label,
    required this.type,
    required this.isOn,
    required this.count,
    required this.onChanged,
  });

  final String label;
  final VenueType type;
  final bool isOn;
  final int count;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!isOn),
      borderRadius: BorderRadius.circular(borderRadiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Icon in a soft circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isOn ? owlPurple.withOpacity(0.18) : white.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                type.icon,
                color: isOn ? owlPurple : greyLighter,
                size: iconSizeSmall,
              ),
            ),
            const SizedBox(width: 12),

            // Label
            Expanded(
              child: Text(
                label,
                style: Styles.basicText,
              ),
            ),

            // Count
            if (count > 0) ...[
              const SizedBox(width: 8),
              Text(
                '($count)',
                style: Styles.smallText.copyWith(color: greyLighter),
              ),
            ],

            // Switch
            Switch.adaptive(
              value: isOn,
              onChanged: onChanged,
              activeColor: owlPurple,
              activeTrackColor: owlPurple.withOpacity(0.4),
              inactiveThumbColor: grey,
              inactiveTrackColor: white.withOpacity(0.12),
            ),
          ],
        ),
      ),
    );
  }
}


