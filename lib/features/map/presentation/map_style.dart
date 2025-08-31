// lib/features/map/presentation/venue_friend_style.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapStyle {
  // Sources
  static const srcVenuesClusterable = 'src_venues_clusterable';
  static const srcVenuesVip = 'src_venues_vip';
  static const srcFriends = 'src_friends';

  // Layers
  static const lyrClusters = 'lyr_clusters';
  static const lyrClusterCount = 'lyr_cluster_count';
  static const lyrUnclustered = 'lyr_unclustered';
  static const lyrLabels = 'lyr_labels';

  static const lyrVip = 'lyr_vip';
  static const lyrVipLabels = 'lyr_vip_labels';

  static const lyrFriendDots = 'lyr_friend_dots';
  static const lyrFriendLabels = 'lyr_friend_labels';

  Future<void> ensure(MapboxMap map) async {
    final style = map.style;

    String _emptyFC() => jsonEncode({'type':'FeatureCollection','features':[]});

    // Venues: clusterable
    if (!await style.styleSourceExists(srcVenuesClusterable)) {
      await style.addSource(GeoJsonSource(
        id: srcVenuesClusterable, data: _emptyFC(),
        cluster: true, clusterRadius: 64, clusterMaxZoom: 15,
      ));
    }
    if (!await style.styleSourceExists(srcVenuesVip)) {
      await style.addSource(GeoJsonSource(id: srcVenuesVip, data: _emptyFC(), cluster: false));
    }

    // Friends
    if (!await style.styleSourceExists(srcFriends)) {
      await style.addSource(GeoJsonSource(id: srcFriends, data: _emptyFC()));
    }

    // Cluster circles
    if (!await style.styleLayerExists(lyrClusters)) {
      await style.addLayer(CircleLayer(id: lyrClusters, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(lyrClusters, 'filter', jsonEncode(['has','point_count']));
      await style.setStyleLayerProperty(lyrClusters, 'circle-color',
          jsonEncode(['step', ['get','point_count'], '#5E60CE', 25, '#4EA8DE', 100, '#48BFE3', 250, '#56CFE1']));
      await style.setStyleLayerProperty(lyrClusters, 'circle-radius',
          jsonEncode(['step', ['get','point_count'], 16, 25, 20, 100, 26, 250, 32]));
      await style.setStyleLayerProperty(lyrClusters, 'circle-stroke-color', '#FFFFFF');
      await style.setStyleLayerProperty(lyrClusters, 'circle-stroke-width', 2.0);
      await style.setStyleLayerProperty(lyrClusters, 'circle-opacity', 0.9);
    }

    // Cluster count
    if (!await style.styleLayerExists(lyrClusterCount)) {
      await style.addLayer(SymbolLayer(id: lyrClusterCount, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(lyrClusterCount, 'filter', jsonEncode(['has','point_count']));
      await style.setStyleLayerProperty(lyrClusterCount, 'text-field', jsonEncode(['get','point_count_abbreviated']));
      await style.setStyleLayerProperty(lyrClusterCount, 'text-size', 12.0);
      await style.setStyleLayerProperty(lyrClusterCount, 'text-color', '#FFFFFF');
      await style.setStyleLayerProperty(lyrClusterCount, 'text-halo-color', '#000000');
      await style.setStyleLayerProperty(lyrClusterCount, 'text-halo-width', 1.2);
    }

    // Unclustered venue dots (border color = open/closed; closed = red)
    if (!await style.styleLayerExists(lyrUnclustered)) {
      await style.addLayer(CircleLayer(id: lyrUnclustered, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(lyrUnclustered, 'filter', jsonEncode(['!', ['has','point_count']]));
      await style.setStyleLayerProperty(lyrUnclustered, 'circle-radius', 8.0);
      await style.setStyleLayerProperty(lyrUnclustered, 'circle-color', '#FFFFFF');
      await style.setStyleLayerProperty(lyrUnclustered, 'circle-stroke-width', 3.0);
      await style.setStyleLayerProperty(lyrUnclustered, 'circle-stroke-color',
          jsonEncode(['case', ['==',['get','isOpenNow'], true], '#2ECC71', '#E74C3C']));
    }

    // Labels above markers: "name • ★rating"
    if (!await style.styleLayerExists(lyrLabels)) {
      await style.addLayer(SymbolLayer(id: lyrLabels, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(lyrLabels, 'filter', jsonEncode(['!', ['has','point_count']]));
      await style.setStyleLayerProperty(lyrLabels, 'text-field',
          jsonEncode(['format',
            ['get','name'], {'text-color':'#000000'},
            '  •  ', {},
            '★', {'text-color':'#FFC107'},
            ['to-string',['get','rating']], {'text-color':'#555555'},
          ]));
      await style.setStyleLayerProperty(lyrLabels, 'text-size', 12.0);
      await style.setStyleLayerProperty(lyrLabels, 'text-halo-color', '#FFFFFF');
      await style.setStyleLayerProperty(lyrLabels, 'text-halo-width', 0.8);
      await style.setStyleLayerProperty(lyrLabels, 'text-offset', const [0.0, -1.6]);
      await style.setStyleLayerProperty(lyrLabels, 'text-allow-overlap', true);
      await style.setStyleLayerProperty(lyrLabels, 'text-ignore-placement', true);
    }

    // VIP (never clustered, 1.5x size)
    if (!await style.styleLayerExists(lyrVip)) {
      await style.addLayer(CircleLayer(id: lyrVip, sourceId: srcVenuesVip));
      await style.setStyleLayerProperty(lyrVip, 'circle-radius', 12.0);
      await style.setStyleLayerProperty(lyrVip, 'circle-color', '#FFFFFF');
      await style.setStyleLayerProperty(lyrVip, 'circle-stroke-width', 3.0);
      await style.setStyleLayerProperty(lyrVip, 'circle-stroke-color',
          jsonEncode(['case', ['==',['get','isOpenNow'], true], '#2ECC71', '#E74C3C']));
    }
    if (!await style.styleLayerExists(lyrVipLabels)) {
      await style.addLayer(SymbolLayer(id: lyrVipLabels, sourceId: srcVenuesVip));
      await style.setStyleLayerProperty(lyrVipLabels, 'text-field',
          jsonEncode(['format',
            ['get','name'], {'text-color':'#000000'},
            '  •  ', {},
            '★', {'text-color':'#FFC107'},
            ['to-string',['get','rating']], {'text-color':'#555555'},
          ]));
      await style.setStyleLayerProperty(lyrVipLabels, 'text-size', 12.0);
      await style.setStyleLayerProperty(lyrVipLabels, 'text-halo-color', '#FFFFFF');
      await style.setStyleLayerProperty(lyrVipLabels, 'text-halo-width', 0.8);
      await style.setStyleLayerProperty(lyrVipLabels, 'text-offset', const [0.0, -1.8]);
      await style.setStyleLayerProperty(lyrVipLabels, 'text-allow-overlap', true);
      await style.setStyleLayerProperty(lyrVipLabels, 'text-ignore-placement', true);
    }

    // Friends
    if (!await style.styleLayerExists(lyrFriendDots)) {
      await style.addLayer(CircleLayer(id: lyrFriendDots, sourceId: srcFriends));
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-color', '#009688');
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-radius', 7.0);
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-opacity', 1.0);
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-stroke-color', '#000000');
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-stroke-width', 1.5);
    }
    if (!await style.styleLayerExists(lyrFriendLabels)) {
      await style.addLayer(SymbolLayer(id: lyrFriendLabels, sourceId: srcFriends));
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-field', jsonEncode(['coalesce',['get','name'],'Friend']));
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-size', 11.0);
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-color', '#000000');
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-halo-color', '#FFFFFF');
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-halo-width', 1.2);
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-offset', const [0.0, -1.2]);
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-allow-overlap', false);
    }
  }

  Future<void> setVenueData(MapboxMap map, {required String clusterableFc, required String vipFc}) async {
    final style = map.style;
    if (await style.styleSourceExists(srcVenuesClusterable)) {
      await style.setStyleSourceProperty(srcVenuesClusterable, 'data', clusterableFc);
    }
    if (await style.styleSourceExists(srcVenuesVip)) {
      await style.setStyleSourceProperty(srcVenuesVip, 'data', vipFc);
    }
  }

  Future<void> setFriendsData(MapboxMap map, String fc) async {
    if (await map.style.styleSourceExists(srcFriends)) {
      await map.style.setStyleSourceProperty(srcFriends, 'data', fc);
    }
  }

  /// Apply layer filters based on UI filter state (open/closed + types).
  Future<void> applyFilters(MapboxMap map, {required bool showClosed, required Set<String> allowedTypes}) async {
    final style = map.style;
    final typeExpr = ['in', ['get','venueType'], ...allowedTypes];
    final openPredicate = ['any', ['==',['get','isOpenNow'], true], ['==',['get','opensLaterToday'], true]];
    final combined = showClosed ? typeExpr : ['all', typeExpr, openPredicate];

    // unclustered & labels
    await style.setStyleLayerProperty(lyrUnclustered, 'filter', jsonEncode(['all', ['!', ['has','point_count']], combined]));
    await style.setStyleLayerProperty(lyrLabels, 'filter', jsonEncode(['all', ['!', ['has','point_count']], combined]));
    // VIP layers
    await style.setStyleLayerProperty(lyrVip, 'filter', jsonEncode(combined));
    await style.setStyleLayerProperty(lyrVipLabels, 'filter', jsonEncode(combined));
  }
}
