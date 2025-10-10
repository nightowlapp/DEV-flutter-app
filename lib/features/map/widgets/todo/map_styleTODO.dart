// lib/features/map/presentation/venue_friend_style.dart
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
  // lyrUnclustered: ID for the layer drawing individual (unclustered) venue dots.
  // lyrLabels: ID for the layer showing text labels above unclustered venues.
  // lyrVip: ID for the layer drawing VIP venue dots (larger size).
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
    String _emptyFC() =>
        jsonEncode({'type': 'FeatureCollection', 'features': []});

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
      await style.addSource(
          GeoJsonSource(id: srcVenuesVip, data: _emptyFC(), cluster: false));
    }

    // Friends - Add source for friend points if missing (no clustering by default).
    if (!await style.styleSourceExists(srcFriends)) {
      await style.addSource(
          GeoJsonSource(id: srcFriends, data: _emptyFC(), cluster: false));
    }

    // Cluster circles - Add layer for drawing clusters as circles if missing.
    // CircleLayer: Renders points as circles.
    // filter: ['has', 'point_count'] - Only show for clustered points (which have a point_count property).
    // circle-color: Step expression - Changes color based on cluster size (point_count):
    //   <25: #5E60CE (purple), 25-99: #4EA8DE (blue), 100-249: #48BFE3 (cyan), >=250: #56CFE1 (light cyan).
    // circle-radius: Step expression - Increases size with cluster size:
    //   <25: 16px, 25-99: 20px, 100-249: 26px, >=250: 32px.
    // circle-stroke-color: #FFFFFF - White border around circle.
    // circle-stroke-width: 2.0px - Border thickness.
    // circle-opacity: 0.9 - 90% opaque.
    if (!await style.styleLayerExists(lyrClusters)) {
      final int minSizeCluser = 350;
      final int maxSizeCluser = 350;

      await style.addLayer(
          CircleLayer(id: lyrClusters, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(
          lyrClusters, 'filter', jsonEncode(['has', 'point_count']));
      await style.setStyleLayerProperty(
          lyrClusters,
          'circle-color',
          jsonEncode([
            'step',
            ['get', 'point_count'],
            purpleAccent.toHex(),
            25,
            purple.toHex(),
            100,
            deepPurple.toHex(),
            maxSizeCluser,
            blue.toHex()
          ]));
      await style.setStyleLayerProperty(
          lyrClusters,
          'circle-radius',
          jsonEncode([
            'step',
            ['get', 'point_count'],
            16,
            25,
            20,
            100,
            26,
            maxSizeCluser,
            34
          ]));
      await style.setStyleLayerProperty(
          lyrClusters, 'circle-stroke-color', white.toHex());
      await style.setStyleLayerProperty(
          lyrClusters, 'circle-stroke-width', 0.0);
      await style.setStyleLayerProperty(lyrClusters, 'circle-opacity', 1.0);
    }

    // Cluster count - Add layer for text inside clusters if missing.
    // SymbolLayer: Renders text or icons.
    // filter: Same as above, only for clusters.
    // text-field: ['get', 'point_count_abbreviated'] - Displays abbreviated count (e.g., 1K for 1000).
    // text-size: 12.0px - Font size.
    // text-color: #FFFFFF - White text.
    // text-halo-color: #000000 - Black outline around text.
    // text-halo-width: 1.2px - Outline thickness.
    if (!await style.styleLayerExists(lyrClusterCount)) {
      await style.addLayer(
          SymbolLayer(id: lyrClusterCount, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(
          lyrClusterCount, 'filter', jsonEncode(['has', 'point_count']));
      await style.setStyleLayerProperty(lyrClusterCount, 'text-field',
          jsonEncode(['get', 'point_count_abbreviated']));
      await style.setStyleLayerProperty(lyrClusterCount, 'text-size', 12.0);
      await style.setStyleLayerProperty(
          lyrClusterCount, 'text-color', white.toHex());
      await style.setStyleLayerProperty(
          lyrClusterCount, 'text-halo-color', '#000000');
      await style.setStyleLayerProperty(
          lyrClusterCount, 'text-halo-width', 1.2);
    }

    // Unclustered venue dots - Add layer for individual venue circles if missing.
    // filter: ['!', ['has', 'point_count']] - Only show for non-clustered points.
    // circle-radius: 8.0px - Size of the dot.
    // circle-color: #FFFFFF - White fill.
    // circle-stroke-width: 3.0px - Border thickness.
    // circle-stroke-color: Case expression - Green (#2ECC71) if 'isOpenNow' is true, else red (#E74C3C).
    if (!await style.styleLayerExists(lyrUnclustered)) {
      await style.addLayer(
          CircleLayer(id: lyrUnclustered, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(
          lyrUnclustered,
          'filter',
          jsonEncode([
            '!',
            ['has', 'point_count']
          ]));
      await style.setStyleLayerProperty(lyrUnclustered, 'circle-radius', 9.0);
      await style.setStyleLayerProperty(
          lyrUnclustered, 'circle-color', purple.toHex());
      await style.setStyleLayerProperty(
          lyrUnclustered, 'circle-stroke-width', 2.0);
      await style.setStyleLayerProperty(
          lyrUnclustered,
          'circle-stroke-color',
          jsonEncode([
            'case',
            [
              '==',
              ['get', 'isOpenNow'],
              true
            ],
            green.toHex(),
            red.toHex()
          ]));
    }

    // Labels above markers - Add layer for venue text labels if missing.
    // filter: Same as unclustered, only non-clusters.
    // text-field: Format expression - Combines: name (black), ' • ' (default color), ★ (yellow #FFC107), rating (gray #555555).
    // text-size: 12.0px.
    // text-halo-color: #FFFFFF - White outline.
    // text-halo-width: 0.8px.
    // text-offset: [0.0, -1.6] - Positions text above the marker (negative y shifts up).
    // text-allow-overlap: true - Allows labels to overlap other symbols.
    // text-ignore-placement: true - Ignores collision detection for placement.
    if (!await style.styleLayerExists(lyrLabels)) {
      await style
          .addLayer(SymbolLayer(id: lyrLabels, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(
          lyrLabels,
          'filter',
          jsonEncode([
            '!',
            ['has', 'point_count']
          ]));
      await style.setStyleLayerProperty(
          lyrLabels,
          'text-field',
          jsonEncode([
            'format',
            ['get', 'name'],
            {'text-color': white.toHex()},
            ' ',
            {},
            '★',
            {'text-color': '#FFC107'},
            [
              'to-string',
              ['get', 'rating']
            ],
            {'text-color': blue.toHex()},
          ]));
      await style.setStyleLayerProperty(lyrLabels, 'text-size', 12.0);
      await style.setStyleLayerProperty(
          lyrLabels, 'text-halo-color', '#FFFFFF');
      await style.setStyleLayerProperty(lyrLabels, 'text-halo-width', 1.0);
      await style
          .setStyleLayerProperty(lyrLabels, 'text-offset', const [0.0, -1.6]);
      await style.setStyleLayerProperty(lyrLabels, 'text-allow-overlap', false);
      await style.setStyleLayerProperty(
          lyrLabels, 'text-ignore-placement', true);
    }

    // VIP - Add layer for VIP venue circles if missing (1.5x larger than regular).
    // circle-radius: 12.0px - Larger size.
    // Other properties similar to unclustered, but no filter here (set in applyFilters).
    if (!await style.styleLayerExists(lyrVip)) {
      await style.addLayer(CircleLayer(id: lyrVip, sourceId: srcVenuesVip));
      await style.setStyleLayerProperty(lyrVip, 'circle-radius', 18.0);
      await style.setStyleLayerProperty(lyrVip, 'circle-color', '#FFFFFF');
      await style.setStyleLayerProperty(lyrVip, 'circle-stroke-width', 3.0);
      await style.setStyleLayerProperty(
          lyrVip,
          'circle-stroke-color',
          jsonEncode([
            'case',
            [
              '==',
              ['get', 'isOpenNow'],
              true
            ],
            green.toHex(),
            red.toHex()
          ]));
    }
    // VIP labels - Similar to regular labels, but with adjusted offset for larger dots.
    // text-offset: [0.0, -1.8] - Slightly further up.
    if (!await style.styleLayerExists(lyrVipLabels)) {
      await style
          .addLayer(SymbolLayer(id: lyrVipLabels, sourceId: srcVenuesVip));
      await style.setStyleLayerProperty(
          lyrVipLabels,
          'text-field',
          jsonEncode([
            'format',
            ['get', 'name'],
            {'text-color': white.toHex()},
            ' ',
            {},
            '★',
            {'text-color': '#FFC107'},
            [
              'to-string',
              ['get', 'rating']
            ],
            {'text-color': blue.toHex()},
          ]));
      await style.setStyleLayerProperty(lyrVipLabels, 'text-size', 14.0);
      await style.setStyleLayerProperty(
          lyrVipLabels, 'text-halo-color', white.toHex());
      await style.setStyleLayerProperty(lyrVipLabels, 'text-halo-width', 0.8);
      await style.setStyleLayerProperty(
          lyrVipLabels, 'text-offset', const [0.0, -1.8]);
      await style.setStyleLayerProperty(
          lyrVipLabels, 'text-allow-overlap', true);
      await style.setStyleLayerProperty(
          lyrVipLabels, 'text-ignore-placement', true);
    }

    // Friends dots - Add layer for friend circles if missing.
    // circle-color: #009688 - Teal fill.
    // circle-radius: 7.0px - Small size.
    // circle-opacity: 1.0 - Fully opaque.
    // circle-stroke-color: #000000 - Black border.
    // circle-stroke-width: 1.5px.
    if (!await style.styleLayerExists(lyrFriendDots)) {
      await style
          .addLayer(CircleLayer(id: lyrFriendDots, sourceId: srcFriends));
      await style.setStyleLayerProperty(
          lyrFriendDots, 'circle-color', blue.toHex());
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-radius', 10.0);
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-opacity', 1.0);
      await style.setStyleLayerProperty(
          lyrFriendDots, 'circle-stroke-color', black.toHex());
      await style.setStyleLayerProperty(
          lyrFriendDots, 'circle-stroke-width', 1.5);
    }
    // Friend labels - Add layer for friend text if missing.
    // text-field: ['coalesce', ['get', 'name'], 'Friend'] - Uses 'name' property if available, else 'Friend'.
    // text-size: 11.0px - Slightly smaller.
    // text-color: #000000 - Black.
    // text-halo-color: #FFFFFF - White outline.
    // text-halo-width: 1.2px.
    // text-offset: [0.0, -1.2] - Above the dot.
    // text-allow-overlap: false - Prevents overlapping other labels.
    if (!await style.styleLayerExists(lyrFriendLabels)) {
      await style
          .addLayer(SymbolLayer(id: lyrFriendLabels, sourceId: srcFriends));
      await style.setStyleLayerProperty(
          lyrFriendLabels,
          'text-field',
          jsonEncode([
            'coalesce',
            ['get', 'name'],
            'Friend'
          ]));
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-size', 12.0);
      await style.setStyleLayerProperty(
          lyrFriendLabels, 'text-color', white.toHex());
      await style.setStyleLayerProperty(
          lyrFriendLabels, 'text-halo-color', black.toHex());
      await style.setStyleLayerProperty(
          lyrFriendLabels, 'text-halo-width', 1.2);
      await style.setStyleLayerProperty(
          lyrFriendLabels, 'text-offset', const [0.0, -1.2]);
      await style.setStyleLayerProperty(
          lyrFriendLabels, 'text-allow-overlap', false);
    }
  }

  // setVenueData: Updates the data in venue sources.
  // clusterableFc: GeoJSON string for clusterable venues.
  // vipFc: GeoJSON string for VIP venues.
  Future<void> setVenueData(MapboxMap map,
      {required String clusterableFc, required String vipFc}) async {
    final style = map.style;
    if (await style.styleSourceExists(srcVenuesClusterable)) {
      await style.setStyleSourceProperty(
          srcVenuesClusterable, 'data', clusterableFc);
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

  /// Apply layer filters based on UI filter state (open/closed + types).
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

    // keep it clean & deterministic
    // Converts set to sorted list for consistent filtering.
    final typesList = allowedTypes.where((e) => e.isNotEmpty).toList()..sort();

    // ✅ correct: `in` takes the value and ONE array (use ['literal', list])
    // typeExpr: Expression to match venueType against allowedTypes.
    // If no types, defaults to ['has', 'venueType'] (show all with a type).
    final typeExpr = typesList.isEmpty
        ? ['has', 'venueType']
        : [
            'in',
            ['get', 'venueType'],
            ['literal', typesList]
          ];

    // openPredicate: 'any' - True if either isOpenNow or opensLaterToday is true.
    final openPredicate = [
      'any',
      [
        '==',
        ['get', 'isOpenNow'],
        true
      ],
      [
        '==',
        ['get', 'opensLaterToday'],
        true
      ],
    ];

    // combined: If showClosed, just type filter; else both type and open.
    final combined = showClosed ? typeExpr : ['all', typeExpr, openPredicate];

    // Applies the combined filter to layers, with additional non-cluster check for unclustered/labels.
    await Future.wait([
      style.setStyleLayerProperty(
        MapStyle.lyrUnclustered,
        'filter',
        jsonEncode([
          'all',
          [
            '!',
            ['has', 'point_count']
          ],
          combined
        ]),
      ),
      style.setStyleLayerProperty(
        MapStyle.lyrLabels,
        'filter',
        jsonEncode([
          'all',
          [
            '!',
            ['has', 'point_count']
          ],
          combined
        ]),
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
