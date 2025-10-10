import 'dart:convert';

import '../../../models/venues/venue.dart';

Map<String, dynamic> venueToFeature(Venue v) => {
      'type': 'Feature',
      'id': v.id,
      'properties': {'id': v.id, 'name': v.displayName},
      'geometry': {
        'type': 'Point',
        'coordinates': [v.entry.lng, v.entry.lat],
      },
    };

String fcFromFeatures(Iterable<Map<String, dynamic>> feats) =>
    jsonEncode({'type': 'FeatureCollection', 'features': feats.toList()});
