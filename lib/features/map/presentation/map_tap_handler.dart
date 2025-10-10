// lib/features/map/services/map_tap_handler.dart
import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:nightowlcode/features/map/presentation/map_style.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

import '../../../data/venue_cache.dart';
import 'map_camera.dart';

typedef OpenVenue = Future<void> Function(String venueId);

class MapTapHandler {
  final mb.MapboxMap map;
  final VenueCache cache;
  final MapCamera camera;

  MapTapHandler({required this.map, required this.cache}) : camera = MapCamera(map);

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

  Future<void> onTap(mb.MapContentGestureContext ctx, {required OpenVenue openVenue}) async {
    debugPrint('🟣 map tap at screen=(${ctx.touchPosition.x}, ${ctx.touchPosition.y})');
    const half = 22.0; // ~44px box
    final box = mb.RenderedQueryGeometry.fromScreenBox(
      mb.ScreenBox(
        min: mb.ScreenCoordinate(x: ctx.touchPosition.x - half, y: ctx.touchPosition.y - half),
        max: mb.ScreenCoordinate(x: ctx.touchPosition.x + half, y: ctx.touchPosition.y + half),
      ),
    );

    // 1) icons & labels (VIP + regular)
    final sym = await map.queryRenderedFeatures(
      box,
      mb.RenderedQueryOptions(layerIds: [
        MapStyle.lyrVip, MapStyle.lyrUnclustered, MapStyle.lyrVipLabels, MapStyle.lyrLabels,
      ]),
    );
    final symId = _firstId(sym);
    if (symId != null && cache.get(symId) != null) {
      return openVenue(symId);
    }

    // 2) backgrounds
    final dots = await map.queryRenderedFeatures(
      box,
      mb.RenderedQueryOptions(layerIds: [MapStyle.lyrVipBg, MapStyle.lyrUnclusteredBg]),
    );
    final dotId = _firstId(dots);
    if (dotId != null && cache.get(dotId) != null) {
      return openVenue(dotId);
    }

    // 3) clusters → zoom in
    final clusters = await map.queryRenderedFeatures(
      box,
      mb.RenderedQueryOptions(layerIds: [MapStyle.lyrClusters]),
    );
    for (final r in clusters) {
      if (r == null) continue;
      final feat  = r.queriedFeature.feature as Map?;
      final props = _asMap(feat?['properties']);
      if (props?['point_count'] != null) {
        final coords = (_asMap(feat?['geometry'])?['coordinates'] as List?)?.cast<num>();
        if (coords != null && coords.length >= 2) {
          final cs = await map.getCameraState();
          await camera.easeTo(
            LatLng(coords[1].toDouble(), coords[0].toDouble()),
            zoom: (cs.zoom + 1.6).clamp(3.0, 20.0),
          );
        }
        return;
      }
    }

    // 4) nearest fallback (if features lacked id for some reason)
    try {
      final worldPt = await map.coordinateForPixel(ctx.touchPosition);
      final pos = worldPt.coordinates as mb.Position;
      final tap = LatLng(pos.lat.toDouble(), pos.lng.toDouble());
      final nearestId = cache.nearest(tap, maxMeters: 60);
      if (nearestId != null) return openVenue(nearestId);
    } catch (_) {}

    debugPrint('tap: nothing hit');
  }
}
