//TODO move all venue related providers in here.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

import '../../../core/storage/venues_sso.dart';
import '../../../models/venues/venue.dart';
import '../../../shared/constants/enums.dart';
import '../other_providers.dart';
import '../time_ticker_provider.dart';


/// Single Source Of Truth for Venues:
/// - Immediately serves locally cached venues (fast start)
/// - On first-ever run (no cache): fetches all venues once and caches them
/// - Then listens for Firestore changes and incrementally updates the cache
/// - Exposes the up-to-date in-memory list at all times
final allVenuesListProvider = Provider<List<Venue>>((ref) {
  final async = ref.watch(venuesSsoProvider);
  return async.maybeWhen(data: (l) => l, orElse: () => const <Venue>[]);
});

/// Grab a single venue by id (updates reactively when SSO changes)
final venueByIdProvider = Provider.family<Venue?, String>((ref, id) {
  final all = ref.watch(allVenuesListProvider);
  //TODO build in safety? Not sure.
  return all.firstWhere((v) => v.id == id);
});

/// Map<String, Venue> built from the SSO list (reactive to SSO changes).
final venuesByIdMapProvider = Provider.autoDispose<Map<String, Venue>>((ref) {
  final list = ref.watch(allVenuesListProvider);
  return {for (final v in list) v.id: v};
});




typedef VenuesFc = ({String clusterable, String vip});

final venuesGeoJsonProvider = Provider<VenuesFc>((ref) {
  final venues = ref.watch(allVenuesListProvider);

  // ⏱ depend on time so we recompute every tick
  final localNow = ref.watch(timeTickerProvider).maybeWhen(
    data: (d) => d,
    orElse: () => DateTime.now(),
  );

  final clusterable = <Map<String, dynamic>>[];
  final vip = <Map<String, dynamic>>[];

  for (final v in venues) {
    // per-venue time-based flags
    final isOpenNow = v.isOpenNow(localNow);
    final isSoon = v.isOpeningOrClosingSoon(
      localNow,
      thresholdMinutes: 60,
    );

    final feat = {
      'type': 'Feature',
      'id': v.id,
      'properties': {
        'id': v.id,
        'name': v.displayName.isNotEmpty
            ? v.displayName
            : Utility.formatString(v.name),
        'rating': v.rating ?? 3.4,
        'venueType': v.type.name,           // "bar", "club", "wine_bar", ...
        'isVerified': v.isVerified,
        'logo_image_id':
        'logo_${v.id}_${(v.updatedAt ?? v.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).millisecondsSinceEpoch}',
        'subscription': v.subscriptionType.name,

        // 🔥 these are what Mapbox style reads
        'isOpenNow': isOpenNow,
        'isSoon': isSoon,

        // optional – not used by style right now, but you might want it:
        'opensLaterToday': v.isOpenToday(localNow),
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [v.entry.lng, v.entry.lat],
      },
    };

    // free → clusterable source, others → VIP source
    if (v.subscriptionType == SubscriptionTypesVenue.free) {
      clusterable.add(feat);
    } else {
      vip.add(feat);
    }
  }

  return (
  clusterable: jsonEncode({
    'type': 'FeatureCollection',
    'features': clusterable,
  }),
  vip: jsonEncode({
    'type': 'FeatureCollection',
    'features': vip,
  }),
  );
});

