// lib/features/map/services/map_camera.dart
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:nightowlcode/shared/utility/lat_lng.dart';

extension MbConverters on LatLng {
  mb.Position toMbPos() => mb.Position(lng, lat); // (lon, lat)
}

class MapCamera {
  final mb.MapboxMap map;
  MapCamera(this.map);

  Future<void> easeTo(LatLng target, {double zoom = 16, int ms = 500}) =>
      map.easeTo(
        mb.CameraOptions(center: mb.Point(coordinates: target.toMbPos()), zoom: zoom),
        mb.MapAnimationOptions(duration: ms),
      );

  Future<void> flyTo(LatLng target, {double zoom = 16, int ms = 900}) =>
      map.flyTo(
        mb.CameraOptions(center: mb.Point(coordinates: target.toMbPos()), zoom: zoom),
        mb.MapAnimationOptions(duration: ms),
      );
}
