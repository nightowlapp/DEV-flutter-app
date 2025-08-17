import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class VenueFriendStyle {
  // Source IDs
  static const srcVenues = 'src_venues';
  static const srcFriends = 'src_friends';

  // Layer IDs
  static const lyrVenueClusters = 'lyr_venue_clusters';
  static const lyrVenueClusterCount = 'lyr_venue_cluster_count';
  static const lyrVenueDots = 'lyr_venue_dots';
  static const lyrVenueLabels = 'lyr_venue_labels';

  static const lyrFriendDots = 'lyr_friend_dots';
  static const lyrFriendLabels = 'lyr_friend_labels';

  Future<void> ensureSourcesAndLayers(MapboxMap map) async {
    // --- Venues (clustered) ---
    if (!await map.style.styleSourceExists(srcVenues)) {
      final empty = jsonEncode({'type': 'FeatureCollection', 'features': []});
      await map.style.addSource(GeoJsonSource(
        id: srcVenues,
        data: empty,
        cluster: true,
        clusterRadius: 64,
        clusterMaxZoom: 15,
      ));
    }

    if (!await map.style.styleLayerExists(lyrVenueClusters)) {
      await map.style.addLayer(CircleLayer(id: lyrVenueClusters, sourceId: srcVenues));
      await map.style.setStyleLayerProperty(lyrVenueClusters, 'filter', jsonEncode(['has', 'point_count']));
      await map.style.setStyleLayerProperty(
        lyrVenueClusters,
        'circle-color',
        jsonEncode(['step', ['get', 'point_count'], '#7C4DFF', 25, '#5E35B1', 100, '#4527A0', 250, '#283593']),
      );
      await map.style.setStyleLayerProperty(lyrVenueClusters, 'circle-opacity', 0.9);
      await map.style.setStyleLayerProperty(lyrVenueClusters, 'circle-stroke-color', '#FFFFFF');
      await map.style.setStyleLayerProperty(lyrVenueClusters, 'circle-stroke-width', 2.0);
      await map.style.setStyleLayerProperty(
        lyrVenueClusters,
        'circle-radius',
        jsonEncode(['step', ['get', 'point_count'], 16, 25, 20, 100, 26, 250, 32]),
      );
    }

    if (!await map.style.styleLayerExists(lyrVenueClusterCount)) {
      await map.style.addLayer(SymbolLayer(id: lyrVenueClusterCount, sourceId: srcVenues));
      await map.style.setStyleLayerProperty(lyrVenueClusterCount, 'filter', jsonEncode(['has', 'point_count']));
      await map.style.setStyleLayerProperty(lyrVenueClusterCount, 'text-field', jsonEncode(['get', 'point_count_abbreviated']));
      await map.style.setStyleLayerProperty(lyrVenueClusterCount, 'text-size', 12.0);
      await map.style.setStyleLayerProperty(lyrVenueClusterCount, 'text-color', '#FFFFFF');
      await map.style.setStyleLayerProperty(lyrVenueClusterCount, 'text-halo-color', '#000000');
      await map.style.setStyleLayerProperty(lyrVenueClusterCount, 'text-halo-width', 1.2);
    }

    if (!await map.style.styleLayerExists(lyrVenueDots)) {
      await map.style.addLayer(CircleLayer(id: lyrVenueDots, sourceId: srcVenues));
      await map.style.setStyleLayerProperty(lyrVenueDots, 'filter', jsonEncode(['!', ['has', 'point_count']]));
      await map.style.setStyleLayerProperty(lyrVenueDots, 'circle-color', '#223AB7');
      await map.style.setStyleLayerProperty(lyrVenueDots, 'circle-radius', 6.0);
      await map.style.setStyleLayerProperty(lyrVenueDots, 'circle-opacity', 0.95);
      await map.style.setStyleLayerProperty(lyrVenueDots, 'circle-stroke-color', '#FFFFFF');
      await map.style.setStyleLayerProperty(lyrVenueDots, 'circle-stroke-width', 1.8);
    }

    if (!await map.style.styleLayerExists(lyrVenueLabels)) {
      await map.style.addLayer(SymbolLayer(id: lyrVenueLabels, sourceId: srcVenues));
      await map.style.setStyleLayerProperty(lyrVenueLabels, 'filter', jsonEncode(['!', ['has', 'point_count']]));
      await map.style.setStyleLayerProperty(lyrVenueLabels, 'text-field', jsonEncode(['coalesce', ['get', 'name'], '']));
      await map.style.setStyleLayerProperty(lyrVenueLabels, 'text-size', 11.0);
      await map.style.setStyleLayerProperty(lyrVenueLabels, 'text-color', '#000000');
      await map.style.setStyleLayerProperty(lyrVenueLabels, 'text-halo-color', '#FFFFFF');
      await map.style.setStyleLayerProperty(lyrVenueLabels, 'text-halo-width', 1.2);
      await map.style.setStyleLayerProperty(lyrVenueLabels, 'text-anchor', 'bottom');
      await map.style.setStyleLayerProperty(lyrVenueLabels, 'text-offset', const [0.0, -1.2]);
      await map.style.setStyleLayerProperty(lyrVenueLabels, 'text-allow-overlap', false);
    }

    // --- Friends ---
    if (!await map.style.styleSourceExists(srcFriends)) {
      final empty = jsonEncode({'type': 'FeatureCollection', 'features': []});
      await map.style.addSource(GeoJsonSource(id: srcFriends, data: empty));
    }

    if (!await map.style.styleLayerExists(lyrFriendDots)) {
      await map.style.addLayer(CircleLayer(id: lyrFriendDots, sourceId: srcFriends));
      await map.style.setStyleLayerProperty(lyrFriendDots, 'circle-color', '#009688');
      await map.style.setStyleLayerProperty(lyrFriendDots, 'circle-radius', 7.0);
      await map.style.setStyleLayerProperty(lyrFriendDots, 'circle-opacity', 1.0);
      await map.style.setStyleLayerProperty(lyrFriendDots, 'circle-stroke-color', '#000000');
      await map.style.setStyleLayerProperty(lyrFriendDots, 'circle-stroke-width', 1.5);
    }

    if (!await map.style.styleLayerExists(lyrFriendLabels)) {
      await map.style.addLayer(SymbolLayer(id: lyrFriendLabels, sourceId: srcFriends));
      await map.style.setStyleLayerProperty(lyrFriendLabels, 'text-field', jsonEncode(['coalesce', ['get', 'name'], 'Friend']));
      await map.style.setStyleLayerProperty(lyrFriendLabels, 'text-size', 11.0);
      await map.style.setStyleLayerProperty(lyrFriendLabels, 'text-color', '#000000');
      await map.style.setStyleLayerProperty(lyrFriendLabels, 'text-halo-color', '#FFFFFF');
      await map.style.setStyleLayerProperty(lyrFriendLabels, 'text-halo-width', 1.2);
      await map.style.setStyleLayerProperty(lyrFriendLabels, 'text-anchor', 'bottom');
      await map.style.setStyleLayerProperty(lyrFriendLabels, 'text-offset', const [0.0, -1.2]);
      await map.style.setStyleLayerProperty(lyrFriendLabels, 'text-allow-overlap', false);
    }
  }

  Future<void> pushGeoJsonString(MapboxMap map, String sourceId, String geoJson) async {
    if (!await map.style.styleSourceExists(sourceId)) return;
    await map.style.setStyleSourceProperty(sourceId, 'data', geoJson);
  }
}
