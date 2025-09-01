import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

class MapStyle {
  // Sources: These are constant strings used as unique IDs for data sources in the map style.
  // srcVenuesClusterable: ID for the source holding clusterable venue points (e.g., free venues that can group into clusters).
  // srcVenuesVip: ID for the source holding VIP venues (non-clusterable, always shown individually).
  // srcFriends: ID for the source holding friend locations.
  static const srcVenuesClusterable = 'src_venues_clusterable';
  static const srcVenuesVip = 'src_venues_vip';
  static const srcFriends = 'src_friends';

  // Layers: These are constant strings used as unique IDs for visual layers in the map style.
  // lyrClusters: ID for the layer drawing cluster circles (grouped venues).
  // lyrClusterCount: ID for the layer showing text counts inside clusters.
  // lyrUnclustered: ID for the layer drawing individual (unclustered) venue icons.
  // lyrLabels: ID for the layer showing text labels above unclustered venues.
  // lyrVip: ID for the layer drawing VIP venue icons (larger size).
  // lyrVipLabels: ID for the layer showing text labels above VIP venues.
  // lyrFriendDots: ID for the layer drawing friend location dots.
  // lyrFriendLabels: ID for the layer showing text labels above friend dots.
  static const lyrClusters = 'lyr_clusters';
  static const lyrClusterCount = 'lyr_cluster_count';
  static const lyrUnclustered = 'lyr_unclustered';
  static const lyrLabels = 'lyr_labels';
  static const lyrVip = 'lyr_vip';
  static const lyrVipLabels = 'lyr_vip_labels';
  static const lyrFriendDots = 'lyr_friend_dots';
  static const lyrFriendLabels = 'lyr_friend_labels';

  // ensure: This method sets up the map sources and layers if they don't exist.
  // It creates empty GeoJSON sources for venues and friends, then adds layers with specific styles.
  Future<void> ensure(MapboxMap map) async {
    final style = map.style;

    // Helper function to create an empty GeoJSON FeatureCollection string.
    // This is used as initial data for sources (empty map features).
    String _emptyFC() => jsonEncode({'type': 'FeatureCollection', 'features': []});

    // Venues: clusterable - Add source for clusterable venues if missing.
    // GeoJsonSource: A source type for point data in GeoJSON format.
    // cluster: true enables clustering of points.
    // clusterRadius: 64 pixels - Points within this distance group into clusters.
    // clusterMaxZoom: 15 - Clustering stops beyond this zoom level.
    if (!await style.styleSourceExists(srcVenuesClusterable)) {
      await style.addSource(GeoJsonSource(
          id: srcVenuesClusterable,
          data: _emptyFC(),
          cluster: true,
          clusterRadius: 64,
          clusterMaxZoom: 15,
        ));
    }
    // Venues: VIP - Add source for non-clusterable VIP venues if missing.
    // cluster: false - These points never cluster.
    if (!await style.styleSourceExists(srcVenuesVip)) {
      await style.addSource(GeoJsonSource(id: srcVenuesVip, data: _emptyFC(), cluster: false));
    }

    // Friends - Add source for friend points if missing (no clustering by default).
    if (!await style.styleSourceExists(srcFriends)) {
      await style.addSource(GeoJsonSource(id: srcFriends, data: _emptyFC(), cluster: false));
    }

    // Cluster circles - Add layer for drawing clusters as circles if missing.
    // CircleLayer: Renders points as circles.
    // filter: ['has', 'point_count'] - Only show for clustered points (which have a point_count property).
    // circle-color: Step expression - Changes color based on cluster size (point_count):
    //   <25: darkOrange, 25-99: lightOrange, 100-349: owlOrange, >=350: promoFg (vibrant orange gradient for nightlife energy).
    // circle-radius: Step expression - Increases size with cluster size:
    //   <25: 20px, 25-99: 25px, 100-349: 30px, >=350: 40px.
    // circle-stroke-width: 0 - No border for clusters.
    // circle-opacity: 1.0 - Fully opaque.
    if (!await style.styleLayerExists(lyrClusters)) {
      final int maxSizeCluster = 350;

      await style.addLayer(CircleLayer(id: lyrClusters, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(lyrClusters, 'filter', jsonEncode(['has', 'point_count']));
      await style.setStyleLayerProperty(lyrClusters, 'circle-color',
        jsonEncode(['step', ['get', 'point_count'], darkOrange.toHex(), 25, lightOrange.toHex(), 100, owlOrange.toHex(), maxSizeCluster, promoFg.toHex()]));
      await style.setStyleLayerProperty(lyrClusters, 'circle-radius',
        jsonEncode(['step', ['get', 'point_count'], 20, 25, 25, 100, 30, maxSizeCluster, 40]));
      await style.setStyleLayerProperty(lyrClusters, 'circle-stroke-width', 0.0);
      await style.setStyleLayerProperty(lyrClusters, 'circle-opacity', 1.0);
    }

    // Cluster count - Add layer for text inside clusters if missing.
    // SymbolLayer: Renders text or icons.
    // filter: Same as above, only for clusters.
    // text-field: ['get', 'point_count_abbreviated'] - Displays abbreviated count (e.g., 1K for 1000).
    // text-size: 14.0px - Slightly larger for visibility.
    // text-color: white - White text for all labels.
    // text-halo-color: black - Black outline for contrast.
    // text-halo-width: 1.2px - Outline thickness.
    if (!await style.styleLayerExists(lyrClusterCount)) {
      await style.addLayer(SymbolLayer(id: lyrClusterCount, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(lyrClusterCount, 'filter', jsonEncode(['has', 'point_count']));
      await style.setStyleLayerProperty(lyrClusterCount, 'text-field', jsonEncode(['get', 'point_count_abbreviated']));
      await style.setStyleLayerProperty(lyrClusterCount, 'text-size', 14.0);
      await style.setStyleLayerProperty(lyrClusterCount, 'text-color', white.toHex());
      await style.setStyleLayerProperty(lyrClusterCount, 'text-halo-color', black.toHex());
      await style.setStyleLayerProperty(lyrClusterCount, 'text-halo-width', 1.2);
    }

    // Unclustered venue icons - Add layer for individual venue icons if missing.
    // SymbolLayer: Renders icons based on venueType.
    // filter: ['!', ['has', 'point_count']] - Only show for non-clustered points.
    // icon-image: Case expression - Maps venueType to icon name (e.g., 'wine_bar', 'club').
    // icon-size: 1.0 - Normal size (12x12px equivalent).
    // icon-halo-color: Case expression - mapOpenGreen if open, else mapClosedRed.
    // icon-halo-width: 2.0px - Border thickness.
    if (!await style.styleLayerExists(lyrUnclustered)) {
      await style.addLayer(SymbolLayer(id: lyrUnclustered, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(lyrUnclustered, 'filter', jsonEncode(['!', ['has', 'point_count']]));
      await style.setStyleLayerProperty(lyrUnclustered, 'icon-image',
        jsonEncode(['case',
            ['==', ['get', 'venueType'], 'wine_bar'], 'wine_bar',
            ['==', ['get', 'venueType'], 'cocktail_bar'], 'cocktail_bar',
            ['==', ['get', 'venueType'], 'beer_bar'], 'beer_bar',
            ['==', ['get', 'venueType'], 'karaoke_bar'], 'karaoke_bar',
            ['==', ['get', 'venueType'], 'sports_bar'], 'sports_bar',
            ['==', ['get', 'venueType'], 'gay_bar'], 'gay_bar',
            ['==', ['get', 'venueType'], 'pub'], 'pub',
            ['==', ['get', 'venueType'], 'bar'], 'bar',
            ['==', ['get', 'venueType'], 'club'], 'club',
            'unknown' // Default for unknown
          ]));
      await style.setStyleLayerProperty(lyrUnclustered, 'icon-size', 1.0);
      await style.setStyleLayerProperty(lyrUnclustered, 'icon-halo-color',
        jsonEncode(['case', ['==', ['get', 'isOpenNow'], true], mapOpenGreen.toHex(), mapClosedRed.toHex()]));
      await style.setStyleLayerProperty(lyrUnclustered, 'icon-halo-width', 2.0);
      await style.setStyleLayerProperty(lyrUnclustered, 'icon-allow-overlap', true);
    }

    // Labels above markers - Add layer for venue text labels if missing.
    // filter: Same as unclustered, only non-clusters.
    // text-field: Format expression - Combines: name (white), ' ' (space), ★ (yellow), rating (white).
    // text-size: 12.0px.
    // text-halo-color: black - Black outline.
    // text-halo-width: 1.0px.
    // text-offset: [0.0, -2.0] - Positions text above the icon.
    // text-allow-overlap: false - Prevents clutter.
    // text-ignore-placement: true - Ignores some collisions.
    if (!await style.styleLayerExists(lyrLabels)) {
      await style.addLayer(SymbolLayer(id: lyrLabels, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(lyrLabels, 'filter', jsonEncode(['!', ['has', 'point_count']]));
      await style.setStyleLayerProperty(lyrLabels, 'text-field',
        jsonEncode(['format',
            ['get', 'name'], {'text-color': white.toHex()},
            ' ', {},
            '★', {'text-color': yellow.toHex()},
            ['to-string', ['get', 'rating']], {'text-color': white.toHex()},
          ]));
      await style.setStyleLayerProperty(lyrLabels, 'text-size', 12.0);
      await style.setStyleLayerProperty(lyrLabels, 'text-halo-color', black.toHex());
      await style.setStyleLayerProperty(lyrLabels, 'text-halo-width', 1.0);
      await style.setStyleLayerProperty(lyrLabels, 'text-offset', const[0.0, -2.0]);
      await style.setStyleLayerProperty(lyrLabels, 'text-allow-overlap', false);
      await style.setStyleLayerProperty(lyrLabels, 'text-ignore-placement', true);
    }

    // VIP - Add layer for VIP venue icons if missing (larger than regular).
    // SymbolLayer: Renders icons based on venueType.
    // icon-image: Same as unclustered, maps venueType to icon.
    // icon-size: 1.5 - Larger size (18x18px equivalent).
    // icon-halo-color: Case expression - mapOpenGreen if open, else mapClosedRed.
    // icon-halo-width: 3.0px - Thicker border.
    if (!await style.styleLayerExists(lyrVip)) {
      await style.addLayer(SymbolLayer(id: lyrVip, sourceId: srcVenuesVip));
      await style.setStyleLayerProperty(lyrVip, 'icon-image',
        jsonEncode(['case',
            ['==', ['get', 'venueType'], 'wine_bar'], 'wine_bar',
            ['==', ['get', 'venueType'], 'cocktail_bar'], 'cocktail_bar',
            ['==', ['get', 'venueType'], 'beer_bar'], 'beer_bar',
            ['==', ['get', 'venueType'], 'karaoke_bar'], 'karaoke_bar',
            ['==', ['get', 'venueType'], 'sports_bar'], 'sports_bar',
            ['==', ['get', 'venueType'], 'gay_bar'], 'gay_bar',
            ['==', ['get', 'venueType'], 'pub'], 'pub',
            ['==', ['get', 'venueType'], 'bar'], 'bar',
            ['==', ['get', 'venueType'], 'club'], 'club',
            'unknown' // Default for unknown
          ]));
      await style.setStyleLayerProperty(lyrVip, 'icon-size', 1.5);
      await style.setStyleLayerProperty(lyrVip, 'icon-halo-color',
        jsonEncode(['case', ['==', ['get', 'isOpenNow'], true], mapOpenGreen.toHex(), mapClosedRed.toHex()]));
      await style.setStyleLayerProperty(lyrVip, 'icon-halo-width', 3.0);
      await style.setStyleLayerProperty(lyrVip, 'icon-allow-overlap', true);
    }

    // VIP labels - Similar to regular labels, but with adjusted offset for larger icons.
    // text-offset: [0.0, -2.5] - Further up.
    if (!await style.styleLayerExists(lyrVipLabels)) {
      await style.addLayer(SymbolLayer(id: lyrVipLabels, sourceId: srcVenuesVip));
      await style.setStyleLayerProperty(lyrVipLabels, 'text-field',
        jsonEncode(['format',
            ['get', 'name'], {'text-color': white.toHex()},
            ' ', {},
            '★', {'text-color': yellow.toHex()},
            ['to-string', ['get', 'rating']], {'text-color': white.toHex()},
          ]));
      await style.setStyleLayerProperty(lyrVipLabels, 'text-size', 14.0);
      await style.setStyleLayerProperty(lyrVipLabels, 'text-halo-color', black.toHex());
      await style.setStyleLayerProperty(lyrVipLabels, 'text-halo-width', 1.0);
      await style.setStyleLayerProperty(lyrVipLabels, 'text-offset', const[0.0, -2.5]);
      await style.setStyleLayerProperty(lyrVipLabels, 'text-allow-overlap', true);
      await style.setStyleLayerProperty(lyrVipLabels, 'text-ignore-placement', true);
    }

    // Friends dots - Add layer for friend circles if missing.
    // circle-color: friendTeal - Teal fill.
    // circle-radius: 10.0px - Compact size.
    // circle-opacity: 1.0 - Fully opaque.
    // circle-stroke-color: black - Black border.
    // circle-stroke-width: 1.5px.
    if (!await style.styleLayerExists(lyrFriendDots)) {
      await style.addLayer(CircleLayer(id: lyrFriendDots, sourceId: srcFriends));
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-color', friendTeal.toHex());
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-radius', 10.0);
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-opacity', 1.0);
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-stroke-color', black.toHex());
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-stroke-width', 1.5);
    }

    // Friend labels - Add layer for friend text if missing.
    // text-field: ['coalesce', ['get', 'name'], 'Friend'] - Uses 'name' property if available, else 'Friend'.
    // text-size: 12.0px.
    // text-color: white - White text for all labels.
    // text-halo-color: black - Black outline.
    // text-halo-width: 1.2px.
    // text-offset: [0.0, -1.5] - Above the dot (adjusted).
    // text-allow-overlap: false - Prevents overlapping.
    if (!await style.styleLayerExists(lyrFriendLabels)) {
      await style.addLayer(SymbolLayer(id: lyrFriendLabels, sourceId: srcFriends));
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-field', jsonEncode(['coalesce', ['get', 'name'], 'Friend']));
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-size', 12.0);
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-color', white.toHex());
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-halo-color', black.toHex());
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-halo-width', 1.2);
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-offset', const[0.0, -1.5]);
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-allow-overlap', false);
    }
  }

  // setVenueData: Updates the data in venue sources.
  // clusterableFc: GeoJSON string for clusterable venues.
  // vipFc: GeoJSON string for VIP venues.
  Future<void> setVenueData(MapboxMap map, {required String clusterableFc, required String vipFc}) async {
    final style = map.style;
    if (await style.styleSourceExists(srcVenuesClusterable)) {
      await style.setStyleSourceProperty(srcVenuesClusterable, 'data', clusterableFc);
    }
    if (await style.styleSourceExists(srcVenuesVip)) {
      await style.setStyleSourceProperty(srcVenuesVip, 'data', vipFc);
    }
  }

  // setFriendsData: Updates the data in the friends source.
  // fc: GeoJSON string for friends.
  Future<void> setFriendsData(MapboxMap map, String fc) async {
    if (await map.style.styleSourceExists(srcFriends)) {
      await map.style.setStyleSourceProperty(srcFriends, 'data', fc);
    }
  }

  // applyFilters: Dynamically filters layers based on showClosed (bool: show closed venues?) and allowedTypes (set of venue types).
  // It builds Mapbox expressions to filter by type and open status.
  // typeExpr: Checks if venueType is in allowedTypes (or any if empty).
  // openPredicate: True if isOpenNow or opensLaterToday.
  // combined: Applies type filter, and open filter if !showClosed.
  // Updates filters on unclustered, labels, VIP, and VIP labels layers.
  Future<void> applyFilters(
    MapboxMap map, {
      required bool showClosed,
      required Set<String> allowedTypes,
    }) async {
    final style = map.style;

    // Converts set to sorted list for consistent filtering.
    final typesList = allowedTypes.where((e) => e.isNotEmpty).toList()..sort();

    // typeExpr: Expression to match venueType against allowedTypes.
    // If no types, defaults to ['has', 'venueType'] (show all with a type).
    final typeExpr = typesList.isEmpty ? ['has', 'venueType'] : ['in', ['get', 'venueType'], ['literal', typesList]];

    // openPredicate: 'any' - True if either isOpenNow or opensLaterToday is true.
    final openPredicate = [
      'any',
      ['==', ['get', 'isOpenNow'], true],
      ['==', ['get', 'opensLaterToday'], true],
    ];

    // combined: If showClosed, just type filter; else both type and open.
    final combined = showClosed ? typeExpr : ['all', typeExpr, openPredicate];

    // Applies the combined filter to layers, with additional non-cluster check for unclustered/labels.
    await Future.wait([
        style.setStyleLayerProperty(
          MapStyle.lyrUnclustered,
          'filter',
          jsonEncode(['all', ['!', ['has', 'point_count']], combined]),
        ),
        style.setStyleLayerProperty(
          MapStyle.lyrLabels,
          'filter',
          jsonEncode(['all', ['!', ['has', 'point_count']], combined]),
        ),
        style.setStyleLayerProperty(
          MapStyle.lyrVip,
          'filter',
          jsonEncode(combined),
        ),
        style.setStyleLayerProperty(
          MapStyle.lyrVipLabels,
          'filter',
          jsonEncode(combined),
        ),
      ]);
  }
}
