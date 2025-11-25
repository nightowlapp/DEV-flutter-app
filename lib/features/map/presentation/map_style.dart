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
  static const lyrLabels = 'lyr_labels'; // non-VIP names
  static const lyrVip = 'lyr_vip';
  static const lyrVipLabels = 'lyr_vip_labels'; // VIP names
  static const lyrFriendDots = 'lyr_friend_dots';
  static const lyrFriendLabels = 'lyr_friend_labels';

  Future<void> ensure(MapboxMap map) async {
    final style = map.style;
    String _emptyFC() =>
        jsonEncode({'type': 'FeatureCollection', 'features': []});

    // --- sources -------------------------------------------------------------
    if (!await style.styleSourceExists(srcVenuesClusterable)) {
      await style.addSource(
        GeoJsonSource(
          id: srcVenuesClusterable,
          data: _emptyFC(),
          cluster: true,
          clusterRadius: 28, // lower = less clustering
          clusterMaxZoom: 12, // up to z12 we cluster non-VIP venues
        ),
      );
    }
    if (!await style.styleSourceExists(srcVenuesVip)) {
      await style.addSource(
        GeoJsonSource(
          id: srcVenuesVip,
          data: _emptyFC(),
          cluster: false, // VIPs never cluster
        ),
      );
    }
    if (!await style.styleSourceExists(srcFriends)) {
      await style.addSource(
        GeoJsonSource(
          id: srcFriends,
          data: _emptyFC(),
          cluster: false,
        ),
      );
    }

    // --- clusters (non-VIP venues) ------------------------------------------
        {
      final int maxSizeCluster = 9999;

      // 1) Ensure the layer exists
      if (!await style.styleLayerExists(lyrClusters)) {
        await style.addLayer(
          CircleLayer(id: lyrClusters, sourceId: srcVenuesClusterable),
        );
      }

      // 2) Always (re)apply properties – hot reload friendly

      await style.setStyleLayerProperty(
        lyrClusters,
        'filter',
        jsonEncode(['has', 'point_count']),
      );

      await style.setStyleLayerProperty(
        lyrClusters,
        'circle-color',
        black.toHex(),
      );

      await style.setStyleLayerProperty(
        lyrClusters,
        'circle-radius',
        jsonEncode([
          'step',
          ['get', 'point_count'],
          20,
          25,
          25,
          100,
          30,
          maxSizeCluster,
          40,
        ]),
      );

      await style.setStyleLayerProperty(
        lyrClusters,
        'circle-stroke-width',
        0.0,
      );
      await style.setStyleLayerProperty(
        lyrClusters,
        'circle-opacity',
        1.0,
      );
    }


    if (!await style.styleLayerExists(lyrClusterCount)) {
      await style.addLayer(
        SymbolLayer(id: lyrClusterCount, sourceId: srcVenuesClusterable),
      );

      await style.setStyleLayerProperty(
        lyrClusterCount,
        'filter',
        jsonEncode(['has', 'point_count']),
      );
      await style.setStyleLayerProperty(
        lyrClusterCount,
        'text-field',
        jsonEncode(['get', 'point_count_abbreviated']),
      );
      await style.setStyleLayerProperty(
        lyrClusterCount,
        'text-size',
        14.0,
      );
      await style.setStyleLayerProperty(
        lyrClusterCount,
        'text-color',
        white.toHex(),
      );
      await style.setStyleLayerProperty(
        lyrClusterCount,
        'text-halo-color',
        black.toHex(),
      );
      await style.setStyleLayerProperty(
        lyrClusterCount,
        'text-halo-width',
        1.2,
      );

      // ✅ keep numbers always visible
      await style.setStyleLayerProperty(
        lyrClusterCount,
        'text-allow-overlap',
        true,
      );
      await style.setStyleLayerProperty(
        lyrClusterCount,
        'text-ignore-placement',
        true,
      );
      await style.setStyleLayerProperty(
        lyrClusterCount,
        'text-opacity',
        1.0,
      );
    }


    // === Small circle backgrounds (non-VIP venue dots) =======================
    if (!await style.styleLayerExists(lyrUnclusteredBg)) {
      await style.addLayer(
        CircleLayer(id: lyrUnclusteredBg, sourceId: srcVenuesClusterable),
      );

      await style.setStyleLayerProperty(
        lyrUnclusteredBg,
        'filter',
        jsonEncode([
          'all',
          ['!', ['has', 'point_count']],
        ]),
      );

      // Non-verified: BLACK dot (no stroke).
      await style.setStyleLayerProperty(
        lyrUnclusteredBg,
        'circle-color',
        black.toHex(), // ⬅️ black background
      );

      // Bigger to hold the icon nicely
      await style.setStyleLayerProperty(
        lyrUnclusteredBg,
        'circle-radius',
        10.0,
      );

      // Hide background for verified (VIP src handles them)
      await style.setStyleLayerProperty(
        lyrUnclusteredBg,
        'circle-opacity',
        jsonEncode([
          'case',
          ['==', ['get', 'isVerified'], true],
          0.0, // verified → no bg here
          1.0, // non-verified → show black circle
        ]),
      );

      // NO STROKE
      await style.setStyleLayerProperty(
        lyrUnclusteredBg,
        'circle-stroke-width',
        0.0,
      );
    }


    // === VIP circle background (just for non-logo cases if any) =============
    if (!await style.styleLayerExists(lyrVipBg)) {
      await style.addLayer(
        CircleLayer(id: lyrVipBg, sourceId: srcVenuesVip),
      );

      await style.setStyleLayerProperty(
        lyrVipBg,
        'circle-color',
        purpleAccent.toHex(),
      );
      await style.setStyleLayerProperty(
        lyrVipBg,
        'circle-radius',
        16.0,
      );

      await style.setStyleLayerProperty(
        lyrVipBg,
        'circle-opacity',
        jsonEncode([
          'case',
          ['==', ['get', 'isVerified'], true],
          0.0,
          1.0,
        ]),
      );

      await style.setStyleLayerProperty(
        lyrVipBg,
        'circle-stroke-width',
        jsonEncode([
          'case',
          ['==', ['get', 'isVerified'], true],
          0.0,
          3.0,
        ]),
      );

      await style.setStyleLayerProperty(
        lyrVipBg,
        'circle-stroke-color',
        jsonEncode([
          'case',
          ['==', ['get', 'isOpenNow'], true],
          green.toHex(),
          red.toHex(),
        ]),
      );
    }

    // === VIP foreground icon ================================================
    if (!await style.styleLayerExists(lyrVip)) {
      await style.addLayer(
        SymbolLayer(id: lyrVip, sourceId: srcVenuesVip),
      );

      await style.setStyleLayerProperty(
        lyrVip,
        'icon-image',
        jsonEncode([
          'case',
          ['==', ['get', 'isVerified'], true],
          [
            'case',
            ['==', ['get', 'isOpenNow'], true],
            ['concat', ['get', 'logo_image_id'], '_open'],
            ['concat', ['get', 'logo_image_id'], '_closed'],
          ],
          [
            'case',
            ['==', ['get', 'venueType'], 'wine_bar'], 'wine_bar',
            ['==', ['get', 'venueType'], 'cocktail_bar'], 'cocktail_bar',
            ['==', ['get', 'venueType'], 'beer_bar'], 'beer_bar',
            ['==', ['get', 'venueType'], 'karaoke_bar'], 'karaoke_bar',
            ['==', ['get', 'venueType'], 'sports_bar'], 'sports_bar',
            ['==', ['get', 'venueType'], 'gay_bar'], 'gay_bar',
            ['==', ['get', 'venueType'], 'pub'], 'pub',
            ['==', ['get', 'venueType'], 'bar'], 'bar',
            ['==', ['get', 'venueType'], 'club'], 'club',
            'unknown',
          ],
        ]),
      );

      await style.setStyleLayerProperty(lyrVip, 'icon-size', 0.9);

      // VIPs should participate in collisions so they don't stack
      await style.setStyleLayerProperty(lyrVip, 'icon-allow-overlap', true);
      await style.setStyleLayerProperty(lyrVip, 'icon-ignore-placement', false);
      await style.setStyleLayerProperty(lyrVip, 'icon-halo-width', 0.0);

      // Reserve some screen space around each VIP marker
      await style.setStyleLayerProperty(
        lyrVip,
        'icon-padding',
        jsonEncode([
          'interpolate',
          ['linear'],
          ['zoom'],
          10,
          18.0, // more padding at low zoom
          15,
          6.0, // less padding when zoomed in
        ]),
      );

      // Place VIPs first so they win collisions vs regular venues
      await style.setStyleLayerProperty(lyrVip, 'symbol-sort-key', 0.0);
    }

    // === Foreground icon for NON-VIP venues ==================================
    if (!await style.styleLayerExists(lyrUnclustered)) {
      await style.addLayer(
        SymbolLayer(id: lyrUnclustered, sourceId: srcVenuesClusterable),
      );

      await style.setStyleLayerProperty(
        lyrUnclustered,
        'filter',
        jsonEncode([
          'all',
          ['!', ['has', 'point_count']],
          ['!=', ['get', 'isVerified'], true], // ⬅️ exclude verified here
        ]),
      );

      await style.setStyleLayerProperty(
        lyrUnclustered,
        'icon-image',
        jsonEncode([
          'case',
          // OPEN → pick *_open variants
          ['==', ['get', 'isOpenNow'], true],
          [
            'case',
            ['==', ['get', 'venueType'], 'wine_bar'], 'wine_bar_open',
            ['==', ['get', 'venueType'], 'cocktail_bar'], 'cocktail_bar_open',
            ['==', ['get', 'venueType'], 'beer_bar'], 'beer_bar_open',
            ['==', ['get', 'venueType'], 'karaoke_bar'], 'karaoke_bar_open',
            ['==', ['get', 'venueType'], 'sports_bar'], 'sports_bar_open',
            ['==', ['get', 'venueType'], 'gay_bar'], 'gay_bar_open',
            ['==', ['get', 'venueType'], 'pub'], 'pub_open',
            ['==', ['get', 'venueType'], 'bar'], 'bar_open',
            ['==', ['get', 'venueType'], 'club'], 'club_open',
            'unknown_open',
          ],

          // CLOSED → pick *_closed variants
          [
            'case',
            ['==', ['get', 'venueType'], 'wine_bar'], 'wine_bar_closed',
            ['==', ['get', 'venueType'], 'cocktail_bar'], 'cocktail_bar_closed',
            ['==', ['get', 'venueType'], 'beer_bar'], 'beer_bar_closed',
            ['==', ['get', 'venueType'], 'karaoke_bar'], 'karaoke_bar_closed',
            ['==', ['get', 'venueType'], 'sports_bar'], 'sports_bar_closed',
            ['==', ['get', 'venueType'], 'gay_bar'], 'gay_bar_closed',
            ['==', ['get', 'venueType'], 'pub'], 'pub_closed',
            ['==', ['get', 'venueType'], 'bar'], 'bar_closed',
            ['==', ['get', 'venueType'], 'club'], 'club_closed',
            'unknown_closed',
          ],
        ]),
      );


      // Slightly smaller so it sits nicely inside the background circle
      await style.setStyleLayerProperty(
        lyrUnclustered,
        'icon-size',
        0.7,
      );

      // 🔴 IMPORTANT PARTS BELOW 🔴

      // 1) Hide VERIFIED icons in this layer (they have their own VIP layer)
      await style.setStyleLayerProperty(
        lyrUnclustered,
        'icon-opacity',
        jsonEncode([
          'case',
          ['==', ['get', 'isVerified'], true],
          0.0,  // verified → don't draw here
          1.0,  // non-verified → visible
        ]),
      );

      // 2) Color NON-VIP icons by open/closed (green/red)
      // Verified are hidden here so no need to branch on isVerified.
      await style.setStyleLayerProperty(
        lyrUnclustered,
        'icon-color',
        jsonEncode([
          'case',
          ['==', ['get', 'isOpenNow'], true],
          green.toHex(),  // open
          red.toHex(),    // closed
        ]),
      );

      // Always draw the icon wherever the dot is visible
      await style.setStyleLayerProperty(lyrUnclustered, 'icon-allow-overlap', true);
      await style.setStyleLayerProperty(lyrUnclustered, 'icon-ignore-placement', false);
      await style.setStyleLayerProperty(lyrUnclustered, 'icon-halo-width', 0.0);

      // keep regular venues below VIP markers
      await style.setStyleLayerProperty(lyrUnclustered, 'symbol-sort-key', 1000.0);
    }


    // ----- Non-VIP labels ----------------------------------------------------
    if (!await style.styleLayerExists(lyrLabels)) {
      await style.addLayer(
        SymbolLayer(id: lyrLabels, sourceId: srcVenuesClusterable),
      );

      await style.setStyleLayerProperty(
        lyrLabels,
        'filter',
        jsonEncode([
          '!',
          ['has', 'point_count'],
        ]),
      );

      await style.setStyleLayerProperty(
        lyrLabels,
        'text-field',
        jsonEncode([
          'format',
          ['get', 'name '],
          {'text-color': white.toHex()},
          '  ',
          {},
          [
            'number-format',
            [
              'coalesce',
              ['get', 'rating'],
              3.4,
            ],
            {
              'min-fraction-digits': 1,
              'max-fraction-digits': 1,
            },
          ],
          {'text-color': white.toHex()},
        ]),
      );

      await style.setStyleLayerProperty(lyrLabels, 'text-size', 10.0);
      await style.setStyleLayerProperty(lyrLabels, 'text-color', white.toHex());
      await style.setStyleLayerProperty(
          lyrLabels, 'text-halo-color', black.toHex());
      await style.setStyleLayerProperty(lyrLabels, 'text-halo-width', 1.25);
      await style.setStyleLayerProperty(lyrLabels, 'text-halo-blur', 0.25);

      await style.setStyleLayerProperty(
        lyrLabels,
        'text-variable-anchor',
        jsonEncode([
          'literal',
          ['top', 'bottom', 'left', 'right'],
        ]),
      );

      await style.setStyleLayerProperty(
        lyrLabels,
        'text-radial-offset',
        jsonEncode([
          'interpolate',
          ['linear'],
          ['zoom'],
          10,
          0.8,
          15,
          1.8,
        ]),
      );

      await style.setStyleLayerProperty(lyrLabels, 'text-padding', 1.0);
      await style.setStyleLayerProperty(lyrLabels, 'text-allow-overlap', false);
      await style.setStyleLayerProperty(
          lyrLabels, 'text-ignore-placement', false);
      await style.setStyleLayerProperty(lyrLabels, 'text-keep-upright', true);

      await style.setStyleLayerProperty(
        lyrLabels,
        'text-opacity',
        jsonEncode([
          'interpolate',
          ['linear'],
          ['zoom'],
          9,
          0.0,
          11,
          1.0,
        ]),
      );

      await style.setStyleLayerProperty(lyrLabels, 'symbol-sort-key', 1100.0);
    }

    // ----- VIP labels --------------------------------------------------------
    if (!await style.styleLayerExists(lyrVipLabels)) {
      await style.addLayer(
        SymbolLayer(id: lyrVipLabels, sourceId: srcVenuesVip),
      );

      await style.setStyleLayerProperty(
        lyrVipLabels,
        'text-field',
        jsonEncode([
          'format',
          ['get', 'name'],
          {'text-color': white.toHex()},
          '  ',
          {},
          [
            'number-format',
            [
              'coalesce',
              ['get', 'rating'],
              3.4,
            ],
            {
              'min-fraction-digits': 1,
              'max-fraction-digits': 1,
            },
          ],
          {'text-color': white.toHex()},
        ]),
      );

      await style.setStyleLayerProperty(lyrVipLabels, 'text-size', 14.0);
      await style.setStyleLayerProperty(
          lyrVipLabels, 'text-color', white.toHex());
      await style.setStyleLayerProperty(
          lyrVipLabels, 'text-halo-color', black.toHex());
      await style.setStyleLayerProperty(
          lyrVipLabels, 'text-halo-width', 1.25);
      await style.setStyleLayerProperty(
          lyrVipLabels, 'text-halo-blur', 0.25);

      await style.setStyleLayerProperty(
        lyrVipLabels,
        'text-variable-anchor',
        jsonEncode([
          'literal',
          ['top', 'bottom', 'left', 'right'],
        ]),
      );

      await style.setStyleLayerProperty(
        lyrVipLabels,
        'text-radial-offset',
        jsonEncode([
          'interpolate',
          ['linear'],
          ['zoom'],
          10,
          0.9,
          16,
          2.0,
        ]),
      );

      await style.setStyleLayerProperty(
          lyrVipLabels, 'text-ignore-placement', false);
      await style.setStyleLayerProperty(
          lyrVipLabels, 'text-keep-upright', true);
      await style.setStyleLayerProperty(
          lyrVipLabels, 'text-allow-overlap', false);

      await style.setStyleLayerProperty(
        lyrVipLabels,
        'text-padding',
        jsonEncode([
          'interpolate',
          ['linear'],
          ['zoom'],
          10,
          20.0,
          14,
          10.0,
        ]),
      );

      await style.setStyleLayerProperty(
        lyrVipLabels,
        'text-opacity',
        jsonEncode([
          'interpolate',
          ['linear'],
          ['zoom'],
          9,
          0.0,
          10,
          0.7,
        ]),
      );

      await style.setStyleLayerProperty(lyrVipLabels, 'symbol-sort-key', 2100.0);
    }

    // --- friends -------------------------------------------------------------
    const friendPartyStatusColor = green;

    if (!await style.styleLayerExists(lyrFriendDots)) {
      await style.addLayer(
        CircleLayer(id: lyrFriendDots, sourceId: srcFriends),
      );
      await style.setStyleLayerProperty(
          lyrFriendDots, 'circle-color', friendColor.toHex());
      await style.setStyleLayerProperty(
          lyrFriendDots, 'circle-radius', 10.0);
      await style.setStyleLayerProperty(
          lyrFriendDots, 'circle-opacity', 1.0);
      await style.setStyleLayerProperty(
          lyrFriendDots, 'circle-stroke-color', friendPartyStatusColor.toHex());
      await style.setStyleLayerProperty(
          lyrFriendDots, 'circle-stroke-width', 1.5);
    }

    if (!await style.styleLayerExists(lyrFriendLabels)) {
      await style.addLayer(
        SymbolLayer(id: lyrFriendLabels, sourceId: srcFriends),
      );
      await style.setStyleLayerProperty(
        lyrFriendLabels,
        'text-field',
        jsonEncode([
          'coalesce',
          ['get', 'name'],
          'Friend',
        ]),
      );
      await style.setStyleLayerProperty(lyrFriendLabels, 'text-size', 12.0);
      await style.setStyleLayerProperty(
          lyrFriendLabels, 'text-color', white.toHex());
      await style.setStyleLayerProperty(
          lyrFriendLabels, 'text-halo-color', black.toHex());
      await style.setStyleLayerProperty(
          lyrFriendLabels, 'text-halo-width', 1.2);
      await style.setStyleLayerProperty(
          lyrFriendLabels, 'text-offset', const [0.0, -1.5]);
      await style.setStyleLayerProperty(
          lyrFriendLabels, 'text-allow-overlap', false);
    }

    // pitch alignment for dots
    await style.setStyleLayerProperty(
        MapStyle.lyrUnclusteredBg, 'circle-pitch-alignment', 'viewport');
    await style.setStyleLayerProperty(
        MapStyle.lyrUnclusteredBg, 'circle-pitch-scale', 'viewport');
    await style.setStyleLayerProperty(
        MapStyle.lyrVipBg, 'circle-pitch-alignment', 'viewport');
    await style.setStyleLayerProperty(
        MapStyle.lyrVipBg, 'circle-pitch-scale', 'viewport');
  }

  Future<void> setVenueData(
      MapboxMap map, {
        required String clusterableFc,
        required String vipFc,
      }) async {
    final style = map.style;
    if (await style.styleSourceExists(srcVenuesClusterable)) {
      await style.setStyleSourceProperty(
        srcVenuesClusterable,
        'data',
        clusterableFc,
      );
    }
    if (await style.styleSourceExists(srcVenuesVip)) {
      await style.setStyleSourceProperty(
        srcVenuesVip,
        'data',
        vipFc,
      );
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
        required String baseClusterableFc,
        required String baseVipFc,
      }) async {
    final style = map.style;

    bool _typeAllowed(Map<String, dynamic> props) {
      final type = props['venueType']?.toString();
      if (allowedTypes.isEmpty) {
        return true; // all types ON
      }
      if (allowedTypes.contains('__none__')) {
        return false; // all OFF
      }
      if (type == null) return false;
      return allowedTypes.contains(type);
    }

    bool _openAllowed(Map<String, dynamic> props) {
      if (showClosed) return true;
      final v = props['isOpenNow'];
      return v == true;
    }

    Map<String, dynamic> _filterFc(String fcJson) {
      final decoded = jsonDecode(fcJson);
      if (decoded is! Map) {
        return <String, dynamic>{
          'type': 'FeatureCollection',
          'features': <dynamic>[],
        };
      }

      final root = Map<String, dynamic>.from(decoded);
      final original = (root['features'] as List?) ?? const <dynamic>[];
      final filtered = <dynamic>[];

      for (final f in original) {
        if (f is! Map) continue;
        final rawProps = f['properties'];
        final props = rawProps is Map
            ? rawProps.cast<String, dynamic>()
            : <String, dynamic>{};

        if (_typeAllowed(props) && _openAllowed(props)) {
          filtered.add(f);
        }
      }

      root['features'] = filtered;
      return root;
    }

    final filteredClusterable = jsonEncode(_filterFc(baseClusterableFc));
    final filteredVip = jsonEncode(_filterFc(baseVipFc));

    if (await style.styleSourceExists(srcVenuesClusterable)) {
      await style.setStyleSourceProperty(
        srcVenuesClusterable,
        'data',
        filteredClusterable,
      );
    }

    if (await style.styleSourceExists(srcVenuesVip)) {
      await style.setStyleSourceProperty(
        srcVenuesVip,
        'data',
        filteredVip,
      );
    }
  }
}
