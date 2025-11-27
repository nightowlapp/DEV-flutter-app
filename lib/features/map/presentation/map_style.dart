// lib/features/map/presentation/map_style.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';

class MapStyle {
  // ======= source ids =======================================================
  static const srcVenuesClusterable = 'src_venues_clusterable';
  static const srcVenuesVip = 'src_venues_vip';
  static const srcFriends = 'src_friends';
  static const srcHotVenues = 'src_hot_venues';

  // ======= layer ids ========================================================
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
  static const lyrFriendIcons  = 'lyr_friend_icons';
  static const lyrFriendLabels = 'lyr_friend_labels';
  static const lyrHotGlowOuter = 'lyr_hot_glow_outer';
  static const lyrHotGlowInner = 'lyr_hot_glow_inner';
  static const lyrHotFlameIcon = 'lyr_hot_flame_icon';

  const MapStyle();

  // small helper so we don't repeat this literal everywhere
  static String _emptyFC() =>
      jsonEncode({'type': 'FeatureCollection', 'features': []});

  // ======================================================================
  // PUBLIC API
  // ======================================================================

  Future<void> ensure(MapboxMap map) async {
    // 1) Data sources
    await _ensureSources(map);

    // 2) Venue clusters + icons/labels
    await _ensureClusterLayers(map);          // cluster circles + counts
    await _ensureNonVipCircleBackground(map); // small purple/black dots
    await _ensureVipCircleBackground(map);    // VIP circle background
    await _ensureVipIcons(map);               // VIP foreground
    await _ensureNonVipIcons(map);            // non-VIP foreground
    await _ensureNonVipLabels(map);           // non-VIP labels
    await _ensureVipLabels(map);              // VIP labels

    // 3) Friends
    await _ensureFriendLayers(map);

    // 4) Shared tweaks
    await _ensureDotPitchAlignment(map);

    // 5) Hot venue flames
    await _ensureHotVenueLayers(map);
  }

  Future<void> setHotVenuesData(MapboxMap map, String fc) async {
    if (await map.style.styleSourceExists(srcHotVenues)) {
      await map.style.setStyleSourceProperty(srcHotVenues, 'data', fc);
    }
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
        required Set<String> favoriteVenueIds,
        bool onlyFavorites = false,
      }) async {
    final style = map.style;

    bool _typeAllowed(Map<String, dynamic> props) {
      final type = props['venueType']?.toString();
      if (allowedTypes.isEmpty) {
        return true; // all types ON
      }
      if (allowedTypes.contains('__none__')) {
        return false; // all OFF sentinel (unless overridden for favorites)
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

        // ----- figure out favorite first -----
        final dynamic rawId =
            props['id'] ?? props['venue_id'] ?? props['venueId'];
        final String? id = rawId == null ? null : rawId.toString();
        final bool isFavorite =
            id != null && favoriteVenueIds.contains(id);

        // ----- type filter (special rules in favorites-only mode) -----
        bool passType;
        if (onlyFavorites) {
          // If user turned ALL types off (we send "__none__"),
          // still allow favorites of ANY type.
          if (allowedTypes.contains('__none__') || allowedTypes.isEmpty) {
            passType = true;
          } else {
            passType = _typeAllowed(props);
          }
        } else {
          passType = _typeAllowed(props);
        }
        if (!passType) continue;

        // ----- open/closed filter -----
        if (!_openAllowed(props)) continue;

        // ----- favorites-only filter -----
        if (onlyFavorites && !isFavorite) continue;

        // mark favorites for styling
        props['isFavorite'] = isFavorite;
        f['properties'] = props;

        filtered.add(f);
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

  // ======================================================================
  // PRIVATE HELPERS – SOURCES
  // ======================================================================

  Future<void> _ensureSources(MapboxMap map) async {
    final style = map.style;

    if (!await style.styleSourceExists(srcHotVenues)) {
      await style.addSource(
        GeoJsonSource(
          id: srcHotVenues,
          data: _emptyFC(),
          cluster: false,
        ),
      );
    }

    // --- sources -----------------------------------------------------------
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
  }

  // ======================================================================
  // PRIVATE HELPERS – CLUSTERS
  // ======================================================================

  Future<void> _ensureClusterLayers(MapboxMap map) async {
    final style = map.style;
    const int maxSizeCluster = 9999;

    // --- clusters (non-VIP venues) ----------------------------------------
        {
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
  }

  // ======================================================================
  // PRIVATE HELPERS – VENUE BACKGROUNDS
  // ======================================================================

  // === Small circle backgrounds (non-VIP venue dots) =======================
  Future<void> _ensureNonVipCircleBackground(MapboxMap map) async {
    final style = map.style;

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
  }

  // === VIP circle background (just for non-logo cases if any) =============
  Future<void> _ensureVipCircleBackground(MapboxMap map) async {
    final style = map.style;

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
          // soon → yellow
          ['==', ['get', 'isSoon'], true],
          yellow.toHex(),

          // open → green
          ['==', ['get', 'isOpenNow'], true],
          green.toHex(),

          // else → red
          red.toHex(),
        ]),
      );
    }
  }

  // ======================================================================
  // PRIVATE HELPERS – VENUE ICONS
  // ======================================================================

  // === VIP foreground icon ================================================
  Future<void> _ensureVipIcons(MapboxMap map) async {
    final style = map.style;

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
      await style.setStyleLayerProperty(
          lyrVip, 'icon-allow-overlap', true);
      await style.setStyleLayerProperty(
          lyrVip, 'icon-ignore-placement', false);
      await style.setStyleLayerProperty(
          lyrVip, 'icon-halo-width', 0.0);

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
      await style.setStyleLayerProperty(
          lyrVip, 'symbol-sort-key', 0.0);
    }
  }

  // === Foreground icon for NON-VIP venues ==================================
  Future<void> _ensureNonVipIcons(MapboxMap map) async {
    final style = map.style;

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
          0.0, // verified → don't draw here
          1.0, // non-verified → visible
        ]),
      );

      // 2) Color NON-VIP icons by open/closed (green/red)
      // Verified are hidden here so no need to branch on isVerified.
      await style.setStyleLayerProperty(
        lyrUnclustered,
        'icon-image',
        jsonEncode([
          'concat',
          // base id: venueType or "unknown"
          ['coalesce', ['get', 'venueType'], 'unknown'],
          // suffix: _isSoon / _open / _closed
          [
            'case',
            ['==', ['get', 'isSoon'], true], '_isSoon',
            ['==', ['get', 'isOpenNow'], true], '_open',
            '_closed',
          ],
        ]),
      );

      // Always draw the icon wherever the dot is visible
      await style.setStyleLayerProperty(
          lyrUnclustered, 'icon-allow-overlap', true);
      await style.setStyleLayerProperty(
          lyrUnclustered, 'icon-ignore-placement', false);
      await style.setStyleLayerProperty(
          lyrUnclustered, 'icon-halo-width', 0.0);

      // keep regular venues below VIP markers
      await style.setStyleLayerProperty(
          lyrUnclustered, 'symbol-sort-key', 1000.0);
    }
  }

  // ======================================================================
  // PRIVATE HELPERS – LABELS
  // ======================================================================

  // ----- Non-VIP labels ----------------------------------------------------
  Future<void> _ensureNonVipLabels(MapboxMap map) async {
    final style = map.style;

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
          ['get', 'name'],
          {}, // no inline color – use layer text-color instead
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
          {}, // rating segment also inherits layer text-color
        ]),
      );

      await style.setStyleLayerProperty(lyrLabels, 'text-size', 10.0);
      await style.setStyleLayerProperty(
        lyrLabels,
        'text-color',
        jsonEncode([
          'case',
          ['==', ['get', 'isFavorite'], true],
          owlPurple.toHex(), // favorite → owl purple
          white.toHex(), // otherwise → white
        ]),
      );

      await style.setStyleLayerProperty(
          lyrLabels, 'text-halo-color', black.toHex());
      await style.setStyleLayerProperty(
          lyrLabels, 'text-halo-width', 1.25);
      await style.setStyleLayerProperty(
          lyrLabels, 'text-halo-blur', 0.25);

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

      await style.setStyleLayerProperty(
          lyrLabels, 'text-padding', 1.0);
      await style.setStyleLayerProperty(
          lyrLabels, 'text-allow-overlap', false);
      await style.setStyleLayerProperty(
          lyrLabels, 'text-ignore-placement', false);
      await style.setStyleLayerProperty(
          lyrLabels, 'text-keep-upright', true);

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

      await style.setStyleLayerProperty(
          lyrLabels, 'symbol-sort-key', 1100.0);
    }
  }

  // ----- VIP labels --------------------------------------------------------
  Future<void> _ensureVipLabels(MapboxMap map) async {
    final style = map.style;

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
          {}, // no inline color – inherit from text-color
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
          {}, // same here
        ]),
      );

      await style.setStyleLayerProperty(
          lyrVipLabels, 'text-size', 14.0);
      await style.setStyleLayerProperty(
        lyrVipLabels,
        'text-color',
        jsonEncode([
          'case',
          ['==', ['get', 'isFavorite'], true],
          owlPurple.toHex(),
          white.toHex(),
        ]),
      );

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

      await style.setStyleLayerProperty(
          lyrVipLabels, 'symbol-sort-key', 2100.0);
    }
  }

  // ======================================================================
  // PRIVATE HELPERS – FRIENDS
  // ======================================================================


  //TODO friends cluster together like venues. When clicked small popup to see names and interactions.
  Future<void> _ensureFriendLayers(MapboxMap map) async {
      final style = map.style;

      // ----- Avatar icon on top of circle -----
      if (!await style.styleLayerExists(lyrFriendIcons)) {
        await style.addLayer(
          SymbolLayer(id: lyrFriendIcons, sourceId: srcFriends),
        );

        await style.setStyleLayerProperty(
          lyrFriendIcons,
          'icon-image',
          jsonEncode([
            'get',
            'avatar_image_id',
          ]),
        );

        await style.setStyleLayerProperty(
          lyrFriendIcons,
          'icon-size',
          1.6,
        );
        await style.setStyleLayerProperty(
          lyrFriendIcons,
          'icon-allow-overlap',
          true,
        );
        await style.setStyleLayerProperty(
          lyrFriendIcons,
          'icon-ignore-placement',
          true,
        );
      }

      // ----- Label: name + time ago -----
      if (!await style.styleLayerExists(lyrFriendLabels)) {
        await style.addLayer(
          SymbolLayer(id: lyrFriendLabels, sourceId: srcFriends),
        );

        await style.setStyleLayerProperty(
          lyrFriendLabels,
          'text-field',
          jsonEncode([
            'format',

            // 1) Name (normal size)
            ['get', 'name'],
            {
              'font-scale': 1.0,
            },

            '\n',
            {},

            // 2) Timestamp (smaller)
            ['get', 'timestamp_pretty'],
            {
              'font-scale': 0.7, // 👈 smaller than name
            },
          ]),
        );

        await style.setStyleLayerProperty(
          lyrFriendLabels,
          'text-size',
          12.0, // base size → name ~12, timestamp ~8.4
        );
        await style.setStyleLayerProperty(
          lyrFriendLabels,
          'text-color',
          blue.toHex(),
        );
        await style.setStyleLayerProperty(
          lyrFriendLabels,
          'text-halo-color',
          black.toHex(),
        );
        await style.setStyleLayerProperty(
          lyrFriendLabels,
          'text-halo-width',
          1.1,
        );
        await style.setStyleLayerProperty(
          lyrFriendLabels,
          'text-offset',
          const [0.0, 3.4],
        );
        await style.setStyleLayerProperty(
          lyrFriendLabels,
          'text-allow-overlap',
          false,
        );
      }
  }


    // ======================================================================
  // PRIVATE HELPERS – PITCH ALIGNMENT
  // ======================================================================

  Future<void> _ensureDotPitchAlignment(MapboxMap map) async { // TODO what does this do?
    final style = map.style;

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

  // ======================================================================
  // PRIVATE HELPERS – HOT VENUE FLAMES
  // ======================================================================

  // === HOT VENUE FLAMES – pulsing glow + emoji ============================
  Future<void> _ensureHotVenueLayers(MapboxMap map) async {
    final style = map.style;

    if (!await style.styleLayerExists(lyrHotGlowOuter)) {
      await style.addLayer(
        CircleLayer(id: lyrHotGlowOuter, sourceId: srcHotVenues),
      );

      await style.setStyleLayerProperty(
        lyrHotGlowOuter,
        'circle-color',
        '#FF4500', // deep orange-red
      );
      await style.setStyleLayerProperty(
        lyrHotGlowOuter,
        'circle-radius',
        18.0, // will be animated
      );
      await style.setStyleLayerProperty(
        lyrHotGlowOuter,
        'circle-blur',
        0.9,
      );
      await style.setStyleLayerProperty(
        lyrHotGlowOuter,
        'circle-opacity',
        0.0, // start invisible, animation will drive this
      );
    }

    if (!await style.styleLayerExists(lyrHotGlowInner)) {
      await style.addLayer(
        CircleLayer(id: lyrHotGlowInner, sourceId: srcHotVenues),
      );

      await style.setStyleLayerProperty(
        lyrHotGlowInner,
        'circle-color',
        '#FFB347', // bright orange
      );
      await style.setStyleLayerProperty(
        lyrHotGlowInner,
        'circle-radius',
        10.0,
      );
      await style.setStyleLayerProperty(
        lyrHotGlowInner,
        'circle-blur',
        0.5,
      );
      await style.setStyleLayerProperty(
        lyrHotGlowInner,
        'circle-opacity',
        0.0,
      );
    }

    if (!await style.styleLayerExists(lyrHotFlameIcon)) {
      await style.addLayer(
        SymbolLayer(id: lyrHotFlameIcon, sourceId: srcHotVenues),
      );

      await style.setStyleLayerProperty(
        lyrHotFlameIcon,
        'text-field',
        jsonEncode('🔥'),
      );
      await style.setStyleLayerProperty(
        lyrHotFlameIcon,
        'text-size',
        18.0,
      );
      await style.setStyleLayerProperty(
        lyrHotFlameIcon,
        'text-color',
        '#FFE66D', // hot yellow
      );
      await style.setStyleLayerProperty(
        lyrHotFlameIcon,
        'text-offset',
        const [0.0, -0.6], // right of the marker
      );
      await style.setStyleLayerProperty(
        lyrHotFlameIcon,
        'text-halo-color',
        '#FF9F1C',
      );
      await style.setStyleLayerProperty(
        lyrHotFlameIcon,
        'text-halo-width',
        1.4,
      );
      await style.setStyleLayerProperty(
        lyrHotFlameIcon,
        'text-allow-overlap',
        true,
      );
      await style.setStyleLayerProperty(
        lyrHotFlameIcon,
        'text-ignore-placement',
        true,
      );
    }
  }
}
