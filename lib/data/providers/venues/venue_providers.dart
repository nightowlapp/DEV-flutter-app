//TODO move all venue related providers in here.


import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

import '../../../models/venues/venue.dart';
import '../../../shared/constants/enums.dart';
import '../../other_providers.dart';

/// Map<String, Venue> built from the SSO list (reactive to SSO changes).
final venuesByIdMapProvider = Provider.autoDispose<Map<String, Venue>>((ref) {
  final list = ref.watch(venuesListProvider);
  return { for (final v in list) v.id : v };
});

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