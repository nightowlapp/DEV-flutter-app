import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../presentation/venue_friend_style.dart';
import '../../../data/repositories/venue_friend_repository.dart';

class MapScreen extends StatefulWidget {
// with AutomaticKeepAliveClientMixin {

  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? _map;
  late final VenueFriendStyle _style;
  late final VenueFriendRepository _repo;

  // Access token here or via native config
  static const _token = 'YOUR_MAPBOX_ACCESS_TOKEN_HERE';

  @override
  void initState() {
    super.initState();
    _style = VenueFriendStyle();
    _repo = VenueFriendRepository(
      mock: true, // set to false to use Firestore
      onVenuesChanged: (geoJson) async {
        if (_map != null) await _style.pushGeoJsonString(_map!, VenueFriendStyle.srcVenues, geoJson);
      },
      onFriendsChanged: (geoJson) async {
        if (_map != null) await _style.pushGeoJsonString(_map!, VenueFriendStyle.srcFriends, geoJson);
      },
    );
  }

  @override
  void dispose() {
    _repo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapWidget(
        // resourceOptions: const ResourceOptions(accessToken: _token),
        styleUri: MapboxStyles.MAPBOX_STREETS,
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(12.5683, 55.6761)), // Copenhagen
          zoom: 12,
        ),
        onMapCreated: _onMapCreated,
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _centerOnCph,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;

    await _map!.location.updateSettings(LocationComponentSettings(
      enabled: true,
      showAccuracyRing: true,
    ));

    await _style.ensureSourcesAndLayers(_map!);

    // Initial query + start friends
    final cam = await _map!.getCameraState();
    final pos = cam.center.coordinates;

    final lat = pos.lat.toDouble();
    final lng = pos.lng.toDouble();

    await _repo.queryVenuesForCamera(lat, lng, cam.zoom, force: true);
    _repo.startFriendsStream(seedLat: lat, seedLng: lng);
  }

  void _centerOnCph() {
    if (_map == null) return;
    _map!.flyTo(
      CameraOptions(center: Point(coordinates: Position(12.5683, 55.6761)), zoom: 12.5),
      MapAnimationOptions(duration: 700),
    );
  }
}
