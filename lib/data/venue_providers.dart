//TODO move all venue related providers in here.


import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

import '../shared/constants/enums.dart';
import 'other_providers.dart';

typedef VenuesFc = ({String clusterable, String vip});

final venuesGeoJsonProvider = Provider<VenuesFc>((ref) {
  final venues = ref.watch(venuesListProvider);
  final clusterable = <Map<String, dynamic>>[];
  final vip = <Map<String, dynamic>>[];

  for (final v in venues) {
    final feat = {
      'type': 'Feature',
      'id': v.id,
      'properties': {
        'id': v.id,
        'name': v.displayName.isNotEmpty ? v.displayName : Utility.formatString(v.name),
        'rating': v.rating ?? 3.4,
        'venueType': v.type.name,
        'subscription': v.subscriptionType.name,
        'isOpenNow': v.isOpenNow(DateTime.now()),
        'opensLaterToday': v.isOpenToday(DateTime.now()),
      },
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

  return (
  clusterable: jsonEncode({'type': 'FeatureCollection', 'features': clusterable}),
  vip:         jsonEncode({'type': 'FeatureCollection', 'features': vip}),
  );
});