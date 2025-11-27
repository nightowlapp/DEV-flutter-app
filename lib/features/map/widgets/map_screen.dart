import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import 'package:nightowlcode/features/map/widgets/share_location_popup.dart';
import 'package:nightowlcode/features/map/widgets/venue_filter_panel.dart';
import 'package:nightowlcode/features/map/widgets/venue_popup.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

import '../../../data/providers/favorite_venues/favorite_venues_provider.dart';
import '../../../data/providers/map_nav_providers.dart';
import '../../../data/providers/real_time_database_providers.dart';
import '../../../data/providers/time_ticker_provider.dart';
import '../../../data/providers/users/friends/friend_profiles_provider.dart';
import '../../../data/providers/users/friends/friends_locations_provider.dart';
import '../../../data/providers/venues/venue_providers.dart';
import '../../../data/services/location/live_location_sharing_provider.dart';
import '../../../data/services/navigation/nav_tts.dart';
import '../../../data/services/navigation/navigation_service.dart';
import '../../../data/services/navigation/route_renderer.dart';
import '../../../models/navigation/nav_models.dart';
import '../../../models/users/friend.dart';
import '../../../models/users/live_location.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/reusable/ui/owl_snack.dart';
import '../../../shared/utility/distance.dart';
import '../presentation/friends_fc.dart';
import '../presentation/initial_camera_provider.dart';
import '../presentation/map_registry/map_images_registry.dart';
import '../presentation/map_style.dart';
import '../presentation/map_registry/map_type_icon_registry.dart';
import '../presentation/navigation_banner.dart';
import 'friend_popup.dart'; // NEW import

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

  String? _lastFriendsFc;
  Map<String, LiveLocation> _latestFriendLocs = const {};
  Map<String, FriendProfile> _latestFriendProfiles = const {};

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
  bool _favoritesOnly = false;
  double? _initialDistance;
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

    // 0) 👥 FRIEND ICONS + LABELS
    final friendsHits = await map.queryRenderedFeatures(
      box,
      mb.RenderedQueryOptions(layerIds: [
          MapStyle.lyrFriendIcons,
          MapStyle.lyrFriendLabels,
        ]),
    );
    debugPrint('tap: friend hits = ${friendsHits.length}');
    final friendId = _firstId(friendsHits);
    if (friendId != null) {
      debugPrint('tap -> friend id: $friendId');
      _openFriendById(friendId);
      return;
    }

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
    final visibleOnMapCount = _visibleVenuesOnMap(allVenues, favoriteIds);
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
          onlyFavorites: _favoritesOnly,
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
        await MapImageRegistry.instance.syncIdToUrl(
          map: map,
          images: idToPath2, // or idToPath2
          maxSize: 46, // logical diameter on the map (same as before)
          pixelRatio: dpr.toDouble(), // e.g. 2.0 or 3.0
        );
      }
    );
    // 1) When locations change
    // 1) When locations change
    ref.listen<AsyncValue<Map<String, LiveLocation>>>(
      friendsLocationsProvider,
      (prev, next) {
        next.whenData((locs) {
            _latestFriendLocs = locs;
            _refreshFriendsOnMap();
          }
        );
      },
    );

    // 2) When user profiles change (names / party status)
    ref.listen<Map<String, FriendProfile>>(
      friendProfilesProvider,
      (prev, next) {
        _latestFriendProfiles = next;
        _refreshFriendsOnMap();
      },
    );

    ref.listen<AsyncValue<DateTime>>(
      timeTickerProvider,
      (prev, next) {
        next.whenData((_) {
            // Only recompute labels, not locations themselves.
            _refreshFriendsOnMap();
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
          onlyFavorites: _favoritesOnly,
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
          if (_navigating) NavigationBanner(
            activeRoute: _activeRoute,
            navDest: _navDest,
            navProfile: _navProfile,
            onStop: _stopNavigation,
            onToggleMute: _toggleMute,
            isMuted: _tts.isMuted,
            initialDistance: _initialDistance,
          ), // REPLACED _navBanner()

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
              child: VenueFilterPanel( // REPLACED _VenueTypeFilterPanel
                selected: _allowedTypes,
                allTypes: _filterableTypes,
                counts: typeCounts,
                venuesByType: venuesByType,
                userLocation: _userLocation,
                favoriteVenueIds: favoriteIds,
                showOnlyOpen: !_showClosed,
                onShowOnlyOpenChanged: (value) async {
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
                    onlyFavorites: _favoritesOnly,
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
                    onlyFavorites: _favoritesOnly,
                  );
                },
                favoritesOnly: _favoritesOnly,
                onFavoritesOnlyChanged: (value) async {
                  final map = _map;
                  if (map == null || !_styleReady) return;
                  setState(() {
                      _favoritesOnly = value;
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
                    onlyFavorites: _favoritesOnly,
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
  /// - All ON → empty set → no type filter (show all)
  /// - All OFF → sentinel '__none__' → hide everything
  /// - Mixed → the selected type names.
  Set<String> _allowedTypeNamesForStyle() {
    // Special case: favorites-only + no type filters
    if (_allowedTypes.isEmpty) {
      if (_favoritesOnly) {
        // Show all types, but MapStyle will still filter to favorites only.
        return {};
      }
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
    MapImageRegistry.instance.clear();
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
      onlyFavorites: _favoritesOnly,
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
    await MapImageRegistry.instance.syncIdToUrl(
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

    await _refreshFriendsOnMap();

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
      _initialDistance = route.distanceMeters;
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
    _initialDistance = null;
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
    // _toast('${v.displayName} is hidden by your filters.');
    // return;
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
        // Respect open/closed filter only when _showClosed == false
        if (!_showClosed && !_isVenueOpenNow(v)) {
          return;
        }
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

  int _visibleVenuesOnMap(List<Venue> allVenues, Set<String> favoriteIds) {
    int total = 0;
    for (final v in allVenues) {
      final type = v.type;
      final isFavorite = favoriteIds.contains(v.id);
      // Favorites-only → drop non-favorites
      if (_favoritesOnly && !isFavorite) continue;
      // Type filter
      if (_allowedTypes.isEmpty) {
        // All type switches OFF:
        // - if not favorites-only → nothing visible
        if (!_favoritesOnly) continue;
        // - if favorites-only → allow favorites of ANY type
      }
      else {
        if (type == null || !_allowedTypes.contains(type)) continue;
      }
      // Open / closed
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
      }
      );
    }
    final fc = jsonEncode({
      'type': 'FeatureCollection',
      'features': features,
    }
    );
    await _style.setHotVenuesData(map, fc);
  }

  Future<void> _refreshFriendsOnMap() async {
    final map = _map;
    if (map == null || !_styleReady) return;

    final dpr = MediaQuery.of(context).devicePixelRatio.clamp(1.0, 3.0);

    // 1) Build spriteId → path (photo or placeholder)
    final idToPath = <String, String>{};

    _latestFriendProfiles.forEach((uid, profile) {
        final statusName = profile.partyStatus?.name ?? 'still_planning';
        final spriteId = 'friend_avatar_${uid}_$statusName';

        final url = profile.photoUrl?.trim();
        if (url != null && url.isNotEmpty) {
          idToPath[spriteId] = url;
        }
        else {
          // 👇 sentinel handled inside MapLogoRegistry._loadAsMbxImage
          idToPath[spriteId] = 'placeholder://friend';
        }
      }
    );

    if (idToPath.isNotEmpty) {
      await MapImageRegistry.instance.syncIdToUrl(
        map: map,
        images: idToPath,
        maxSize: 32,
        pixelRatio: dpr.toDouble(),
      );
    }

    // 2) Push updated GeoJSON
    final fc = friendsToFeatureCollection(
      _latestFriendLocs,
      _latestFriendProfiles,
    );
    _lastFriendsFc = fc;

    await _style.setFriendsData(map, fc);
  }

  Future<void> _openFriendById(String uid) async {
    final profile = _latestFriendProfiles[uid];
    final loc = _latestFriendLocs[uid];

    if (profile == null || loc == null || !mounted) {
      debugPrint('tap friend "$uid": no profile or location yet');
      return;
    }

    // 👉 auto-center on friend
    await _navigateTo(LatLng(loc.lat, loc.lng), zoom: 16);

    final root = Navigator.of(context, rootNavigator: true).context;

    // await showFriendPopupSheet( //TODO implement
    //   root,
    //   uid: uid,
    //   profile: profile,
    //   loc: loc,
    //   onMessage: () {
    //     // TODO: open chat / profile screen
    //   },
    // );
  }


}






bool _isVenueOpenNow(Venue v) => v.isOpenNow(DateTime.now());
