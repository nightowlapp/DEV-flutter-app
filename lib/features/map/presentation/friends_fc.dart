// lib/features/map/presentation/friends_fc.dart
import 'dart:convert';

import '../../../models/users/live_location.dart';

String friendsToFeatureCollection(Map<String, LiveLocation> m) {
  final features = m.values.map((e) => {
        'type': 'Feature',
        'id': e.uid,
        'properties': {
          'id': e.uid,
          'name': e.uid, // swap for display_name if you have it
          'timestamp_ms':
              e.timestamp.millisecondsSinceEpoch, // client-side usage
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [e.lng, e.lat],
        },
      });
  return jsonEncode(
      {'type': 'FeatureCollection', 'features': features.toList()});
}
