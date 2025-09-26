// lib/features/map/presentation/map_style.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

class MapStyle {
  static const srcVenuesClusterable = 'src_venues_clusterable';
  static const srcVenuesVip = 'src_venues_vip';
  static const srcFriends = 'src_friends';

  static const lyrClusters = 'lyr_clusters';
  static const lyrClusterCount = 'lyr_cluster_count';

  // Purple circle backgrounds (small)
  static const lyrUnclusteredBg = 'lyr_unclustered_bg';
  static const lyrVipBg = 'lyr_vip_bg';

  static const lyrUnclustered = 'lyr_unclustered';
  static const lyrLabels = 'lyr_labels';
  static const lyrVip = 'lyr_vip';
  static const lyrVipLabels = 'lyr_vip_labels';
  static const lyrFriendDots = 'lyr_friend_dots';
  static const lyrFriendLabels = 'lyr_friend_labels';

  Future<void> ensure(MapboxMap map) async {
    final style = map.style;
    String _emptyFC() => jsonEncode({'type': 'FeatureCollection', 'features': []});

    // --- sources -------------------------------------------------------------
    if (!await style.styleSourceExists(srcVenuesClusterable)) {
      await style.addSource(GeoJsonSource(
          id: srcVenuesClusterable,
          data: _emptyFC(),
          cluster: true,
          clusterRadius: 64,
          clusterMaxZoom: 15,
        ));
    }
    if (!await style.styleSourceExists(srcVenuesVip)) {
      await style.addSource(GeoJsonSource(id: srcVenuesVip, data: _emptyFC(), cluster: false));
    }
    if (!await style.styleSourceExists(srcFriends)) {
      await style.addSource(GeoJsonSource(id: srcFriends, data: _emptyFC(), cluster: false));
    }

    // --- clusters ------------------------------------------------------------
    if (!await style.styleLayerExists(lyrClusters)) {
      final int maxSizeCluster = 9999;
      await style.addLayer(CircleLayer(id: lyrClusters, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(lyrClusters, 'filter', jsonEncode(['has', 'point_count']));
      await style.setStyleLayerProperty(
        lyrClusters,
        'circle-color',
        jsonEncode([
            'step', ['get', 'point_count'],
            deepPurple.toHex(), 25,
            purple.toHex(), 100,
            purpleAccent.toHex(), maxSizeCluster,
            promoFg.toHex()
          ]),
      );
      await style.setStyleLayerProperty(
        lyrClusters,
        'circle-radius',
        jsonEncode(['step', ['get', 'point_count'], 20, 25, 25, 100, 30, maxSizeCluster, 40]),
      );
      await style.setStyleLayerProperty(lyrClusters, 'circle-stroke-width', 0.0);
      await style.setStyleLayerProperty(lyrClusters, 'circle-opacity', 1.0);
    }

    if (!await style.styleLayerExists(lyrClusterCount)) {
      await style.addLayer(SymbolLayer(id: lyrClusterCount, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(lyrClusterCount, 'filter', jsonEncode(['has', 'point_count']));
      await style.setStyleLayerProperty(lyrClusterCount, 'text-field', jsonEncode(['get', 'point_count_abbreviated']));
      await style.setStyleLayerProperty(lyrClusterCount, 'text-size', 14.0);
      await style.setStyleLayerProperty(lyrClusterCount, 'text-color', white.toHex());
      await style.setStyleLayerProperty(lyrClusterCount, 'text-halo-color', black.toHex());
      await style.setStyleLayerProperty(lyrClusterCount, 'text-halo-width', 1.2);
    }

    // === Small circle backgrounds (venue dots) ===============================
    // Lighten the fill AND add green/red stroke based on feature property `isOpenNow`
    // If verified -> transparent fill (logo sits on map), still keep the status ring.
    if (!await style.styleLayerExists(lyrUnclusteredBg)) {
      await style.addLayer(CircleLayer(id: lyrUnclusteredBg, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(lyrUnclusteredBg, 'filter', jsonEncode(['all', ['!', ['has', 'point_count']]]));

      await style.setStyleLayerProperty(
        lyrUnclusteredBg,
        'circle-color',
        jsonEncode(['case',
            ['==', ['get', 'isVerified'], true], 'rgba(0,0,0,0)',  // transparent when verified
            purple.toHex(),
          ]),
      );
      await style.setStyleLayerProperty(lyrUnclusteredBg, 'circle-radius', 8.0);
      await style.setStyleLayerProperty(lyrUnclusteredBg, 'circle-opacity', 1);
      await style.setStyleLayerProperty(lyrUnclusteredBg, 'circle-stroke-width', 3.0);
      await style.setStyleLayerProperty(
        lyrUnclusteredBg,
        'circle-stroke-color',
        jsonEncode(['case', ['==', ['get', 'isOpenNow'], true], green.toHex(), red.toHex()]),
      );
    }

    if (!await style.styleLayerExists(lyrVipBg)) {
      await style.addLayer(CircleLayer(id: lyrVipBg, sourceId: srcVenuesVip));

      await style.setStyleLayerProperty(
        lyrVipBg,
        'circle-color',
        jsonEncode(['case',
            ['==', ['get', 'isVerified'], true], 'rgba(0,0,0,0)',
            purpleAccent.toHex(),
          ]),
      );
      await style.setStyleLayerProperty(lyrVipBg, 'circle-radius', 16.0);
      await style.setStyleLayerProperty(lyrVipBg, 'circle-opacity', 1);
      await style.setStyleLayerProperty(lyrVipBg, 'circle-stroke-width', 3.0);
      await style.setStyleLayerProperty(
        lyrVipBg,
        'circle-stroke-color',
        jsonEncode(['case', ['==', ['get', 'isOpenNow'], true], green.toHex(), red.toHex()]),
      );
    }

    // === Foreground icon (inside the circle) =================================
    if (!await style.styleLayerExists(lyrUnclustered)) {
      await style.addLayer(SymbolLayer(id: lyrUnclustered, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(lyrUnclustered, 'filter', jsonEncode(['!', ['has', 'point_count']]));

      await style.setStyleLayerProperty(
        lyrUnclustered,
        'icon-image',
        jsonEncode([
            'case',
            ['==', ['get', 'isVerified'], true], ['get', 'logo_url'],
            ['case',
              ['==', ['get', 'venueType'], 'wine_bar'], 'wine_bar',
              ['==', ['get', 'venueType'], 'cocktail_bar'], 'cocktail_bar',
              ['==', ['get', 'venueType'], 'beer_bar'], 'beer_bar',
              ['==', ['get', 'venueType'], 'karaoke_bar'], 'karaoke_bar',
              ['==', ['get', 'venueType'], 'sports_bar'], 'sports_bar',
              ['==', ['get', 'venueType'], 'gay_bar'], 'gay_bar',
              ['==', ['get', 'venueType'], 'pub'], 'pub',
              ['==', ['get', 'venueType'], 'bar'], 'bar',
              ['==', ['get', 'venueType'], 'club'], 'club',
              'unknown'
            ]
          ]),
      );
      await style.setStyleLayerProperty(lyrUnclustered, 'icon-size', 0.8);
      await style.setStyleLayerProperty(lyrUnclustered, 'icon-allow-overlap', true);
      await style.setStyleLayerProperty(lyrUnclustered, 'icon-halo-width', 0.0);
      // Make symbols sit on top so taps hit them first.
      await style.setStyleLayerProperty(lyrUnclustered, 'symbol-sort-key', 1000);
    }

    if (!await style.styleLayerExists(lyrLabels)) {
      await style.addLayer(SymbolLayer(id: lyrLabels, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(lyrLabels, 'filter', jsonEncode(['!', ['has', 'point_count']]));
      await style.setStyleLayerProperty(
        lyrLabels,
        'text-field',
        jsonEncode([
          'format',
          // ['get', 'name'], {'text-color': white.toHex()},
          // '  ', {},
          // rating with exactly 1 decimal
          [
            'number-format',
            ['coalesce', ['get', 'rating'], 3.4], // fallback 0 if null
            {
              'min-fraction-digits': 1,
              'max-fraction-digits': 1,
            }
          ],
          {'text-color': white.toHex()},
        ]),
      );
      await style.setStyleLayerProperty(lyrLabels, 'text-size', 12.0);
      await style.setStyleLayerProperty(lyrLabels, 'text-halo-color', black.toHex());
      await style.setStyleLayerProperty(lyrLabels, 'text-halo-width', 1.0);
      await style.setStyleLayerProperty(lyrLabels, 'text-offset', const[0.0, -2.0]);
      await style.setStyleLayerProperty(lyrLabels, 'text-allow-overlap', false);
      await style.setStyleLayerProperty(lyrLabels, 'text-ignore-placement', true);
    }

    if (!await style.styleLayerExists(lyrVip)) {
      await style.addLayer(SymbolLayer(id: lyrVip, sourceId: srcVenuesVip));
      await style.setStyleLayerProperty(
        lyrVip,
        'icon-image',
        jsonEncode([
            'case',
            ['==', ['get', 'isVerified'], true], ['get', 'logo_url'],
            ['case',
              ['==', ['get', 'venueType'], 'wine_bar'], 'wine_bar',
              ['==', ['get', 'venueType'], 'cocktail_bar'], 'cocktail_bar',
              ['==', ['get', 'venueType'], 'beer_bar'], 'beer_bar',
              ['==', ['get', 'venueType'], 'karaoke_bar'], 'karaoke_bar',
              ['==', ['get', 'venueType'], 'sports_bar'], 'sports_bar',
              ['==', ['get', 'venueType'], 'gay_bar'], 'gay_bar',
              ['==', ['get', 'venueType'], 'pub'], 'pub',
              ['==', ['get', 'venueType'], 'bar'], 'bar',
              ['==', ['get', 'venueType'], 'club'], 'club',
              'unknown'
            ]
          ]),
      );
      await style.setStyleLayerProperty(lyrVip, 'icon-size', 0.95);
      await style.setStyleLayerProperty(lyrVip, 'icon-allow-overlap', true);
      await style.setStyleLayerProperty(lyrVip, 'icon-halo-width', 0.0);
      await style.setStyleLayerProperty(lyrVip, 'symbol-sort-key', 1000);
    }

    if (!await style.styleLayerExists(lyrVipLabels)) {
      await style.addLayer(SymbolLayer(id: lyrVipLabels, sourceId: srcVenuesVip));
      await style.setStyleLayerProperty(
        lyrVipLabels,
        'text-field',
        jsonEncode([
            'format',
            ['get', 'name'], {'text-color': white.toHex()},
            '  ', {},
            // rating with exactly 1 decimal
            [
              'number-format',
              ['coalesce', ['get', 'rating'], 3.4], // fallback 0 if null
              {
                'min-fraction-digits': 1,
                'max-fraction-digits': 1,
              }
            ],
            {'text-color': white.toHex()},
          ]),
      );
      await style.setStyleLayerProperty(lyrVipLabels, 'text-size', 14.0);
      await style.setStyleLayerProperty(lyrVipLabels, 'text-halo-color', black.toHex());
      await style.setStyleLayerProperty(lyrVipLabels, 'text-halo-width', 1.0);
      await style.setStyleLayerProperty(lyrVipLabels, 'text-offset', const[0.0, -2.5]);
      await style.setStyleLayerProperty(lyrVipLabels, 'text-allow-overlap', true);
      await style.setStyleLayerProperty(lyrVipLabels, 'text-ignore-placement', true);
    }

    // friends
    const friendPartyStatusColor = green;
    if (!await style.styleLayerExists(lyrFriendDots)) {
      await style.addLayer(CircleLayer(id: lyrFriendDots, sourceId: srcFriends));
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-color', friendColor.toHex());
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-radius', 10.0);
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-opacity', 1.0);
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-stroke-color', friendPartyStatusColor.toHex());
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-stroke-width', 1.5);
    }

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

    await style.setStyleLayerProperty(MapStyle.lyrUnclusteredBg, 'circle-pitch-alignment', 'viewport');
    await style.setStyleLayerProperty(MapStyle.lyrUnclusteredBg, 'circle-pitch-scale', 'viewport');
    await style.setStyleLayerProperty(MapStyle.lyrVipBg, 'circle-pitch-alignment', 'viewport');
    await style.setStyleLayerProperty(MapStyle.lyrVipBg, 'circle-pitch-scale', 'viewport');

    await style.setStyleLayerProperty(MapStyle.lyrVipBg, 'circle-pitch-alignment', 'viewport');
    await style.setStyleLayerProperty(MapStyle.lyrVipBg, 'circle-pitch-scale', 'viewport');

  }

  Future<void> setVenueData(
    MapboxMap map, {
      required String clusterableFc,
      required String vipFc,
    }) async {
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

  Future<void> applyFilters(
    MapboxMap map, {
      required bool showClosed,
      required Set<String> allowedTypes,
    }) async {
    final style = map.style;

    final typesList = allowedTypes.where((e) => e.isNotEmpty).toList()..sort();
    final typeExpr = typesList.isEmpty ? ['has', 'venueType'] : ['in', ['get', 'venueType'], ['literal', typesList]];

    final openPredicate = [
      'any',
      ['==', ['get', 'isOpenNow'], true],
      ['==', ['get', 'opensLaterToday'], true],
    ];

    final combined = showClosed ? typeExpr : ['all', typeExpr, openPredicate];

    await Future.wait([
        style.setStyleLayerProperty(
          MapStyle.lyrUnclusteredBg,
          'filter',
          jsonEncode(['all', ['!', ['has', 'point_count']], combined]),
        ),
        style.setStyleLayerProperty(
          MapStyle.lyrUnclustered,
          'filter',
          jsonEncode(['all', ['!', ['has', 'point_count']], combined]),
        ),
        style.setStyleLayerProperty(MapStyle.lyrLabels, 'filter', jsonEncode(['all', ['!', ['has', 'point_count']], combined])),
        style.setStyleLayerProperty(MapStyle.lyrVipBg, 'filter', jsonEncode(combined)),
        style.setStyleLayerProperty(MapStyle.lyrVip, 'filter', jsonEncode(combined)),
        style.setStyleLayerProperty(MapStyle.lyrVipLabels, 'filter', jsonEncode(combined)),
      ]);
  }
}
