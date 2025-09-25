// lib/features/map/widgets/map_screen.dart
import 'package:flutter/material.dart' hide Viewport;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nightowlcode/features/map/widgets/venue_popup.dart';

import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/enums.dart'; // VenueType
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';

import '../../../data/other_providers.dart';
import '../../../data/services/location/location_controller.dart';
import '../../../data/providers/venues/venue_providers.dart'; // <-- assumes allVenuesStreamProvider & venuesGeoJsonProvider live here
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

  final MapStyle _style = MapStyle();

  // Keep a lightweight cache of venues to resolve taps -> Venue
  final Map<String, Venue> _venuesById = {};

  // Filters you already had
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

    // Ensure style and apply filters
    await _style.ensure(_map!);
    await _style.applyFilters(
      _map!,
      showClosed: _showClosed,
      allowedTypes: _allowedTypes.map((e) => e.name).toSet(),
    );

    // Push whatever we already have (synchronously)
    final fcNow = ref.read(venuesGeoJsonProvider);
    await _style.setVenueData(
      _map!,
      clusterableFc: fcNow.clusterable,
      vipFc: fcNow.vip,
    );

    if (mounted) setState(() => _loading = false);
  }

  // Open your bottom sheet
  void _openVenueById(String id) {
    final v = _venuesById[id];
    if (v == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => VenuePopup(
        venue: v,
        onClose: () => Navigator.of(context).pop(),
        onOpenDetails: () {
          // TODO: navigate to full venue page if needed
        },
      ),
    );
  }

  // Minimal tap handler using queryRenderedFeatures
  Future<void> _onMapTap(MapContentGestureContext ctx) async {
    if (_map == null) return;

    final geometry =
    RenderedQueryGeometry.fromScreenCoordinate(ctx.touchPosition);

    final results = await _map!.queryRenderedFeatures(
      geometry,
      RenderedQueryOptions(
        // Only ask our two venue symbol layers (no clusters)
        layerIds: [MapStyle.lyrVip, MapStyle.lyrUnclustered],
      ),
    );

    for (final r in results) {
      if (r == null) continue;

      // Map<String?, Object?> structure
      final featMap = r.queriedFeature.feature;
      final props =
      (featMap['properties'] as Map?)?.cast<String, Object?>();
      final rawId =
      (props != null && props['id'] != null) ? props['id'] : featMap['id'];
      final id = rawId?.toString();

      if (id != null) {
        _openVenueById(id);
        return;
      }
    }
    // Tap didn’t hit our layers -> do nothing
  }

  Future<void> _centerOnUser() async {
    final cam = await ref.read(initialCameraProvider.future);
    _map?.flyTo(cam,  MapAnimationOptions(duration: 800));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Keep the map sources in sync
    ref.listen<VenuesFc>(venuesGeoJsonProvider, (prev, next) async {
      if (_map == null) return;
      await _style.setVenueData(
        _map!,
        clusterableFc: next.clusterable,
        vipFc: next.vip,
      );
    });

    // Keep a local id->Venue cache for quick popup lookup
    ref.listen<AsyncValue<List<Venue>>>(allVenuesStreamProvider,
            (prev, next) {
          next.whenData((list) {
            for (final v in list) {
              _venuesById[v.id] = v;
            }
          });
        });

    // Center animation updates
    ref.listen<AsyncValue<CameraOptions>>(initialCameraProvider, (prev, next) {
      next.whenData((cam) {
        _map?.flyTo(cam, MapAnimationOptions(duration: 650));
      });
    });

    // Show map immediately with fallback camera
    final camAsync = ref.watch(initialCameraProvider);
    final cam = camAsync.maybeWhen(
      data: (c) => c,
      orElse: () => fallbackCamera,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('mapWidget'),
            styleUri: MapboxStyles.DARK,
            cameraOptions: cam,
            onMapCreated: _onMapCreated,
            onTapListener: _onMapTap, // ⬅️ minimal addition
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
}
