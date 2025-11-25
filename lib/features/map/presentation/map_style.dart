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
      await style.addSource(GeoJsonSource(
        id: srcVenuesClusterable,
        data: _emptyFC(),
        cluster: true,
        clusterRadius: 24, //Cluster config. Lower numbers less clustering.
        clusterMaxZoom: 12, //Cluster config. Lower numbers less clustering.
      ));
    }
    if (!await style.styleSourceExists(srcVenuesVip)) {
      await style.addSource(
          GeoJsonSource(id: srcVenuesVip, data: _emptyFC(), cluster: false));
    }
    if (!await style.styleSourceExists(srcFriends)) {
      await style.addSource(
          GeoJsonSource(id: srcFriends, data: _emptyFC(), cluster: false));
    }

    // --- clusters ------------------------------------------------------------
    if (!await style.styleLayerExists(lyrClusters)) {
      final int maxSizeCluster = 9999;
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
            maxSizeCluster,
            blue.toHex()
          ]));

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
          40
        ]),
      );
      await style.setStyleLayerProperty(
          lyrClusters, 'circle-stroke-width', 0.0);
      await style.setStyleLayerProperty(lyrClusters, 'circle-opacity', 1.0);
    }

    if (!await style.styleLayerExists(lyrClusterCount)) {
      await style.addLayer(
          SymbolLayer(id: lyrClusterCount, sourceId: srcVenuesClusterable));
      await style.setStyleLayerProperty(
          lyrClusterCount, 'filter', jsonEncode(['has', 'point_count']));
      await style.setStyleLayerProperty(lyrClusterCount, 'text-field',
          jsonEncode(['get', 'point_count_abbreviated']));
      await style.setStyleLayerProperty(lyrClusterCount, 'text-size', 14.0);
      await style.setStyleLayerProperty(
          lyrClusterCount, 'text-color', white.toHex());
      await style.setStyleLayerProperty(
          lyrClusterCount, 'text-halo-color', black.toHex());
      await style.setStyleLayerProperty(
          lyrClusterCount, 'text-halo-width', 1.2);
    }

    // === Small circle backgrounds (venue dots) ===============================
    // Lighten the fill AND add green/red stroke based on feature property `isOpenNow`
    // If verified -> transparent fill (logo sits on map), still keep the status ring.
    // === Small circle backgrounds (venue dots) ===============================
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

      // Non-verified: purple dot + green/red stroke.
      await style.setStyleLayerProperty(
        lyrUnclusteredBg,
        'circle-color',
        purple.toHex(),
      );

      // ⬅️ make the dot a bit larger so the icon has room
      await style.setStyleLayerProperty(
        lyrUnclusteredBg,
        'circle-radius',
        10.0, // was 8.0
      );

      await style.setStyleLayerProperty(
        lyrUnclusteredBg,
        'circle-opacity',
        jsonEncode([
          'case',
          ['==', ['get', 'isVerified'], true],
          0.0, // hide for verified
          1.0,
        ]),
      );

      await style.setStyleLayerProperty(
        lyrUnclusteredBg,
        'circle-stroke-width',
        jsonEncode([
          'case',
          ['==', ['get', 'isVerified'], true],
          0.0,
          3.0,
        ]),
      );

      await style.setStyleLayerProperty(
        lyrUnclusteredBg,
        'circle-stroke-color',
        jsonEncode([
          'case',
          ['==', ['get', 'isOpenNow'], true],
          green.toHex(),
          red.toHex(),
        ]),
      );
    }



    if (!await style.styleLayerExists(lyrVipBg)) {
      await style.addLayer(CircleLayer(id: lyrVipBg, sourceId: srcVenuesVip));

      await style.setStyleLayerProperty(
          lyrVipBg, 'circle-color', purpleAccent.toHex());
      await style.setStyleLayerProperty(lyrVipBg, 'circle-radius', 16.0);

      await style.setStyleLayerProperty(
        lyrVipBg,
        'circle-opacity',
        jsonEncode([
          'case',
          [
            '==',
            ['get', 'isVerified'],
            true
          ],
          0.0,
          1.0,
        ]),
      );

      await style.setStyleLayerProperty(
        lyrVipBg,
        'circle-stroke-width',
        jsonEncode([
          'case',
          [
            '==',
            ['get', 'isVerified'],
            true
          ],
          0.0,
          3.0,
        ]),
      );

      await style.setStyleLayerProperty(
        lyrVipBg,
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
        ]),
      );
    }

    if (!await style.styleLayerExists(lyrVip)) {
      await style.addLayer(SymbolLayer(id: lyrVip, sourceId: srcVenuesVip));
      await style.setStyleLayerProperty(
        lyrVip,
        'icon-image',
        jsonEncode([
          'case',
          [
            '==',
            ['get', 'isVerified'],
            true
          ],
          [
            'case',
            [
              '==',
              ['get', 'isOpenNow'],
              true
            ],
            [
              'concat',
              ['get', 'logo_image_id'],
              '_open'
            ],
            [
              'concat',
              ['get', 'logo_image_id'],
              '_closed'
            ],
          ],
          [
            'case',
            [
              '==',
              ['get', 'venueType'],
              'wine_bar'
            ],
            'wine_bar',
            [
              '==',
              ['get', 'venueType'],
              'cocktail_bar'
            ],
            'cocktail_bar',
            [
              '==',
              ['get', 'venueType'],
              'beer_bar'
            ],
            'beer_bar',
            [
              '==',
              ['get', 'venueType'],
              'karaoke_bar'
            ],
            'karaoke_bar',
            [
              '==',
              ['get', 'venueType'],
              'sports_bar'
            ],
            'sports_bar',
            [
              '==',
              ['get', 'venueType'],
              'gay_bar'
            ],
            'gay_bar',
            [
              '==',
              ['get', 'venueType'],
              'pub'
            ],
            'pub',
            [
              '==',
              ['get', 'venueType'],
              'bar'
            ],
            'bar',
            [
              '==',
              ['get', 'venueType'],
              'club'
            ],
            'club',
            'unknown'
          ]
        ]),
      );
      await style.setStyleLayerProperty(lyrVip, 'icon-size', 0.9);

      // VIPs should collide (so they push others away),
      // not just overlap everything.
      await style.setStyleLayerProperty(lyrVip, 'icon-allow-overlap', true);
      await style.setStyleLayerProperty(lyrVip, 'icon-halo-width', 0.0);

      // 💥 Reserve more screen space around VIP icons at mid zoom:
      await style.setStyleLayerProperty(
        lyrVip,
        'icon-padding',
        jsonEncode([
          'interpolate', ['linear'], ['zoom'],
          10, 20.0,
          14, 10.0,
        ]),
      );

      // Higher priority than regular symbols
      await style.setStyleLayerProperty(lyrVip, 'symbol-sort-key', 2000.0);
    }


    // === Foreground icon (inside the circle) =================================
    if (!await style.styleLayerExists(lyrUnclustered)) {
      await style.addLayer(
        SymbolLayer(id: lyrUnclustered, sourceId: srcVenuesClusterable),
      );
      await style.setStyleLayerProperty(
        lyrUnclustered,
        'filter',
        jsonEncode([
          '!', ['has', 'point_count'],
        ]),
      );

      await style.setStyleLayerProperty(
        lyrUnclustered,
        'icon-image',
        jsonEncode([
          'case',
          // VERIFIED → logo sprite (your CircleAvatar PNG)
          ['==', ['get', 'isVerified'], true],
          [
            'case',
            ['==', ['get', 'isOpenNow'], true],
            ['concat', ['get', 'logo_image_id'], '_open'],
            ['concat', ['get', 'logo_image_id'], '_closed'],
          ],

          // REGULAR → type icon name
          [
            'case',
            ['==', ['get', 'venueType'], 'wine_bar'],      'wine_bar',
            ['==', ['get', 'venueType'], 'cocktail_bar'],  'cocktail_bar',
            ['==', ['get', 'venueType'], 'beer_bar'],      'beer_bar',
            ['==', ['get', 'venueType'], 'karaoke_bar'],   'karaoke_bar',
            ['==', ['get', 'venueType'], 'sports_bar'],    'sports_bar',
            ['==', ['get', 'venueType'], 'gay_bar'],       'gay_bar',
            ['==', ['get', 'venueType'], 'pub'],           'pub',
            ['==', ['get', 'venueType'], 'bar'],           'bar',
            ['==', ['get', 'venueType'], 'club'],          'club',
            'unknown',
          ],
        ]),
      );

      // ⬅️ slightly smaller so it sits neatly inside the circle
      await style.setStyleLayerProperty(
        lyrUnclustered,
        'icon-size',
        0.7, // was 0.9 – tweak to taste
      );

      // ⬅️ make **regular** venue-type icons white
      // (this tints SDF icons; PNG logos for verified venues are unaffected)
      await style.setStyleLayerProperty(
        lyrUnclustered,
        'icon-color',
        jsonEncode([
          'case',
          ['==', ['get', 'isVerified'], true],
          // verified logos: icon-color has no effect on non-SDF PNGs,
          // but we return a value anyway
          white.toHex(),
          // regular venues: white type icon
          white.toHex(),
        ]),
      );

      // Let them collide + be pushed by VIPs
      await style.setStyleLayerProperty(lyrUnclustered, 'icon-allow-overlap', false);
      await style.setStyleLayerProperty(lyrUnclustered, 'icon-halo-width', 0.0);
      await style.setStyleLayerProperty(lyrUnclustered, 'symbol-sort-key', 1000.0);
    }



    // ----- Non-VIP labels (automatic de-clutter) -----
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
          ['get', 'name '], {'text-color': white.toHex()},
          '  ', {},
          [
            'number-format',
            [
              'coalesce',
              ['get', 'rating'],
              3.4
            ], // fallback 0 if null
            {
              'min-fraction-digits': 1,
              'max-fraction-digits': 1,
            }
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

      // Automatic placement around the marker to reduce collisions
      await style.setStyleLayerProperty(
        lyrLabels,
        'text-variable-anchor',
        jsonEncode([
          'literal',
          ['top', 'bottom', 'left', 'right']
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
          16,
          1.8
        ]),
      );
      await style.setStyleLayerProperty(lyrLabels, 'text-padding', 1.0);
      await style.setStyleLayerProperty(lyrLabels, 'text-allow-overlap', false);
      await style.setStyleLayerProperty(
          lyrLabels, 'text-ignore-placement', false);
      await style.setStyleLayerProperty(lyrLabels, 'text-keep-upright', true);

      // Fade in with zoom to keep low-zoom map cleaner
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
          1.0
        ]),
      );

      // Draw above regular dots but below VIP labels
      await style.setStyleLayerProperty(lyrLabels, 'symbol-sort-key', 1100.0);
    }




    // ----- VIP labels (automatic de-clutter) -----
    // ----- VIP labels (automatic de-clutter) -----
    if (!await style.styleLayerExists(lyrVipLabels)) {
      await style
          .addLayer(SymbolLayer(id: lyrVipLabels, sourceId: srcVenuesVip));

      await style.setStyleLayerProperty(
        lyrVipLabels,
        'text-field',
        jsonEncode([
          'format',
          ['get', 'name'], {'text-color': white.toHex()},
          '  ', {},
          [
            'number-format',
            [
              'coalesce',
              ['get', 'rating'],
              3.4
            ],
            {
              'min-fraction-digits': 1,
              'max-fraction-digits': 1,
            }
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
          ['top', 'bottom', 'left', 'right']
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
          2.0
        ]),
      );
      await style.setStyleLayerProperty(
          lyrVipLabels, 'text-ignore-placement', false);
      await style.setStyleLayerProperty(
          lyrVipLabels, 'text-keep-upright', true);
      await style.setStyleLayerProperty(
          lyrVipLabels, 'text-allow-overlap', false);

      // Give VIP labels some extra collision padding too
      await style.setStyleLayerProperty(
        lyrVipLabels,
        'text-padding',
        jsonEncode([
          'interpolate', ['linear'], ['zoom'],
          10, 20.0,
          14, 10.0,
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
          11,
          1.0
        ]),
      );

      // VIP labels above everything else
      await style.setStyleLayerProperty(lyrVipLabels, 'symbol-sort-key', 2100.0);
    }


    // friends
    const friendPartyStatusColor = green;
    if (!await style.styleLayerExists(lyrFriendDots)) {
      await style
          .addLayer(CircleLayer(id: lyrFriendDots, sourceId: srcFriends));
      await style.setStyleLayerProperty(
          lyrFriendDots, 'circle-color', friendColor.toHex());
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-radius', 10.0);
      await style.setStyleLayerProperty(lyrFriendDots, 'circle-opacity', 1.0);
      await style.setStyleLayerProperty(
          lyrFriendDots, 'circle-stroke-color', friendPartyStatusColor.toHex());
      await style.setStyleLayerProperty(
          lyrFriendDots, 'circle-stroke-width', 1.5);
    }

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
          lyrFriendLabels, 'text-offset', const [0.0, -1.5]);
      await style.setStyleLayerProperty(
          lyrFriendLabels, 'text-allow-overlap', false);
    }

    await style.setStyleLayerProperty(
        MapStyle.lyrUnclusteredBg, 'circle-pitch-alignment', 'viewport');
    await style.setStyleLayerProperty(
        MapStyle.lyrUnclusteredBg, 'circle-pitch-scale', 'viewport');
    await style.setStyleLayerProperty(
        MapStyle.lyrVipBg, 'circle-pitch-alignment', 'viewport');
    await style.setStyleLayerProperty(
        MapStyle.lyrVipBg, 'circle-pitch-scale', 'viewport');

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
          srcVenuesClusterable, 'data', clusterableFc);
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
        required String baseClusterableFc,
        required String baseVipFc,
      }) async {
    final style = map.style;

    // Interpret your sentinel semantics:
    // - allowedTypes == {}          → all types ON
    // - allowedTypes contains '__none__' → all OFF
    bool _typeAllowed(Map<String, dynamic> props) {
      final type = props['venueType']?.toString();
      if (allowedTypes.isEmpty) {
        // All ON
        return true;
      }
      if (allowedTypes.contains('__none__')) {
        // All OFF
        return false;
      }
      if (type == null) return false;
      return allowedTypes.contains(type);
    }

    bool _openAllowed(Map<String, dynamic> props) {
      if (showClosed) return true;
      final v = props['isOpenNow'];
      // Treat anything non-true as "closed"
      return v == true;
    }

    Map<String, dynamic> _filterFc(String fcJson) {
      final decoded = jsonDecode(fcJson);
      if (decoded is! Map) {
        // fallback to empty FC if something is weird
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

    final filteredClusterable =
    jsonEncode(_filterFc(baseClusterableFc));
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
