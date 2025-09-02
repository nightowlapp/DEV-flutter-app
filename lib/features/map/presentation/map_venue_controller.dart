import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/other_providers.dart';                // allVenuesStreamProvider
import '../../../models/venues/venue.dart';
import '../../../shared/constants/enums.dart';
import 'mappers.dart';                // fcFromFeatures, venueToFeature (see note below)

/* Output for the map: two FCs (clusterable/free + vip/paying) */
class MapVenuesGeoJson {
  final String clusterableFc;
  final String vipFc;
  const MapVenuesGeoJson({required this.clusterableFc, required this.vipFc});
}

/* StreamProvider that transforms Venue -> GeoJSON */
final mapVenuesGeoJsonProvider = StreamProvider<MapVenuesGeoJson>((ref) {
  // Use the live stream of all venues
  final src$ = ref.watch(allVenuesStreamProvider.stream);

  return src$.map((venues) {
    final clusterable = <Map<String, dynamic>>[];
    final vip = <Map<String, dynamic>>[];

    for (final v in venues) {
      // Properties expected by your MapStyle:
      final props = <String, dynamic>{
        'id': v.id,
        'name': v.displayName.isNotEmpty ? v.displayName : v.name,
        'rating': v.rating ?? 0.0,
        'venueType': v.type.name,
        'subscription': v.subscriptionType.name,
        // keep it simple for now so pins look "open" (green)
        'isOpenNow': true,
        'opensLaterToday': true,
      };

      final feat = {
        'type': 'Feature',
        'id': v.id,
        'properties': props,
        'geometry': {
          'type': 'Point',
          'coordinates': [v.entry.lng, v.entry.lat],
        },
      };

      if (v.subscriptionType == SubscriptionTypesVenue.free) {
        clusterable.add(feat);
      } else {
        vip.add(feat);
      }
    }

    return MapVenuesGeoJson(
      clusterableFc: fcFromFeatures(clusterable),
      vipFc: fcFromFeatures(vip),
    );
  });
});
