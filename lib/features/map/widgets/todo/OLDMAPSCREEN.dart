import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nightowlcode/features/main/widgets/main_app_bar.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import '../../../../shared/constants/icons.dart';
import '../../../../shared/constants/values.dart';

class OLDMapScreen extends ConsumerStatefulWidget {
// with AutomaticKeepAliveClientMixin {
  const OLDMapScreen({super.key});

  @override
  ConsumerState<OLDMapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<OLDMapScreen> {
  MapboxMap? _map;
  bool _mapCreated = false;
  CameraOptions? _initialCamera;


  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      // If you have a service, you can use it here. Fallback used if it throws.
      // final loc = await ref.read(locationServiceProvider).getUserPosition();
      // final lat = loc.latitude ??;
      // final lng = loc.longitude;

      // Mocked/fallback location (Copenhagen)
      const lat = 55.6761;
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
      // Hard fallback
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

    await _map?.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        // pulsingEnabled: true,
        // pulsingColor: owlOrange.value,
        accuracyRingColor: owlOrange.value,
        accuracyRingBorderColor: white.value,
        showAccuracyRing: true,
      ),
    );

    await _map?.scaleBar.updateSettings(ScaleBarSettings(enabled: false, isMetricUnits: true));
    // await _map?.logo.updateSettings(LogoSettings(enabled: true)); // illegal to disable
    await _map?.attribution.updateSettings(AttributionSettings(clickable: false, iconColor: transparent.value)); // illegal to disable
    // await _map?.compass.updateSettings(CompassSettings(fadeWhenFacingNorth: false, image: ));
  }

  void _centerOnUser() {
    if (_map == null) return;

    // Hardcoded fallback (replace with real user location if available)
    const lat = 55.6761;
    const lng = 12.5683;

    _map!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: mapZoomDefault,
      ),
      MapAnimationOptions(duration: 800),
      //Todo cool animations
    );
  }

  void _topDownView() {
    if (_map == null) return;
    _map!.easeTo(
      CameraOptions(pitch: 0),
      MapAnimationOptions(duration: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialCamera == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            styleUri: MapboxStyles.SATELLITE,
            cameraOptions: _initialCamera!,
            onMapCreated: _onMapCreated,
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'centerUser',
                  mini: true,
                  tooltip: 'Center on user',
                  onPressed: _centerOnUser,
                  child: const Icon(Icons.my_location),
                ),
                // const SizedBox(height: 10),
                // FloatingActionButton(
                //   heroTag: 'topDown',
                //   mini: true,
                //   tooltip: 'Top-down view',
                //   onPressed: _topDownView,
                //   child: const Icon(Icons.screen_rotation_alt),
                // ),
              ],
            ),
          ),
          // Positioned(
          //   top: 12,
          //   left: 12,
          //
          //   child:           IconButton(
          //   tooltip: _showClosed ? 'Hide closed' : 'Show closed',
          //   icon: Icon(_showClosed ? Icons.visibility : Icons.visibility_off),
          //   onPressed: () async {
          //     setState(() => _showClosed = !_showClosed);
          //     final m = _map;
          //     if (m != null) {
          //       await _style.applyFilters(m, showClosed: _showClosed, allowedTypes: _allowedTypes);
          //     }
          //   },
          // ),
          // )
        ],
      ),
    );
  }
}
