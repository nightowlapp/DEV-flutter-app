// lib/features/explore/search/venue_search_engine.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/distance.dart';

import 'search_query.dart';

typedef NowInTz = DateTime Function(String? tzid);

final venueSearchEngineProvider =
    Provider.autoDispose<VenueSearchEngine>((ref) {
  //TODO go in depth at some point.
  // If you have a real tz resolver, inject it here. Fallback: device time.
  final nowInTz = (String? _) => DateTime.now();
  return VenueSearchEngine(nowInTz: nowInTz);
});

class VenueSearchEngine {
  VenueSearchEngine({required this.nowInTz});

  final NowInTz nowInTz;

  /// Filter a ranked list by the query.
  List<Venue> filter(List<Venue> input, SearchQuery q) {
    if (q.isEmpty) return input;
    final spec = _parse(q);
    return input.where((v) => _matches(v, spec)).toList(growable: false);
  }

  // ---------- parsing ----------
  _Spec _parse(SearchQuery q) {
    final spec = _Spec();
    for (final raw in q.terms) {
      final t = raw.trim();

      // OPEN
      if (t == 'open' || t == 'opennow' || t == 'opennow' || t == 'now') {
        spec.openNow = true;
        continue;
      }
      if (t == 'opentoday' || t == 'today') {
        spec.openToday = true;
        continue;
      }

      // VERIFIED
      if (t == 'verified' || t == 'official') {
        spec.verifiedOnly = true;
        continue;
      }

      // AGE: 18+, age:18, age>=18
      final age = _parseNumberWithPlus(t, prefixes: const ['age', 'a']);
      if (age != null && age >= 18) {
        // 10..40 → age restriction
        spec.minAge = age;
        continue;
      }

      // RATING: r:4.2, rating>=4, 4.5★, 4+, (numbers <= 5 are assumed rating)
      final rating = _parseRating(t);
      if (rating != null) {
        spec.minRating = rating;
        continue;
      }

      // PRICE: price<=10 / p<=10 / €10 / $10 (simple "max price")
      final price = _parsePriceMax(t);
      if (price != null) {
        spec.maxPrice = price;
        continue;
      }

      // TYPE: enum name or synonyms (club, bar, pub, lounge, etc.)
      final type = _parseType(t);
      if (type != null) {
        spec.types.add(type);
        continue;
      }

      // DISTANCE: within:5km / <=5km (optional)
      final distKm = _parseDistanceKm(t);
      if (distKm != null) {
        spec.maxDistanceKm = distKm;
        continue;
      }

      // otherwise → text term
      spec.textTerms.add(t);
    }
    return spec;
  }

  // ---------- match ----------
  bool _matches(Venue v, _Spec s) {
    // TODO make tags and all the others
    final now = nowInTz(v.timeZoneId);

    // OPEN
    if (s.openNow == true && !v.isOpenNow(now)) return false;
    if (s.openToday == true && !v.isOpenToday(now)) return false;

    // VERIFIED
    if (s.verifiedOnly == true && !v.isVerified) return false;

    // AGE
    if (s.minAge != null) {
      final eff = v.effectiveAgeRestriction(now);
      if (eff < s.minAge!) return false;
    }

    // RATING
    if (s.minRating != null) {
      final r = v.rating ?? 0;
      if (r < s.minRating!) return false;
    }

    // PRICE
    if (s.maxPrice != null) {
      final p = v.effectiveEntryPrice(now);
      if (p > s.maxPrice!) return false;
    }

    // TYPE
    if (s.types.isNotEmpty && !s.types.contains(v.type)) return false;

    // DISTANCE
    if (s.maxDistanceKm != null && s.userLoc != null) {
      final m = Distance.metersLatLng(s.userLoc!, v.entry);
      if (m > (s.maxDistanceKm! * 1000)) return false;
    }

    // TEXT: name/alt name/desc/city + some numeric fields formatted
    if (s.textTerms.isNotEmpty) {
      final blob =
          _normalize('${v.displayName.isNotEmpty ? v.displayName : v.name} '
              '${v.description} ${v.city} '
              '${v.countryCode} '
              '${v.defaultAgeRestriction}+ '
              '${v.rating?.toStringAsFixed(1) ?? ''} '
              '${describeEnum(v.type)}');
      for (final term in s.textTerms) {
        if (!blob.contains(term)) return false;
      }
    }

    return true;
  }

  String _normalize(String s) => SearchQuery.removeDiacritics(s.toLowerCase());

  // ---------- helpers ----------
  double? _parseRating(String t) {
    final star = t.replaceAll('★', '');
    // rating:4.2 / r:4 / rating>=4 / r>=4
    final p = RegExp(r'^(r|rating)[:=<>]*\s*([0-5](?:\.\d)?)$');
    final m = p.firstMatch(star);
    if (m != null) return double.tryParse(m.group(2)!);

    // 4.5+ or >=4
    final p2 = RegExp(r'^(?:>=)?([0-5](?:\.\d)?)(\+)?$');
    final m2 = p2.firstMatch(star);
    if (m2 != null) return double.tryParse(m2.group(1)!);

    return null;
  }

  int? _parseNumberWithPlus(String t, {required List<String> prefixes}) {
    // age:18+, age>=18, 18+
    final prefixRx = prefixes.isEmpty ? '' : '(?:${prefixes.join('|')})';
    final rx = RegExp('^(?:$prefixRx)?[:=<>]*\\s*(\\d{1,2})(\\+)?\$');
    final m = rx.firstMatch(t);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  VenueType? _parseType(String t) {
    final m = _typeMap[t] ?? _typeMap[_normalize(t)];
    return m;
  }

  double? _parsePriceMax(String t) {
    // price<=10 / p<=10 / €10 / $10
    final rx = RegExp(
        r'^(?:price|p)?\s*(?:<=|=|:)?\s*(?:€|\$)?\s*([0-9]+(?:\.[0-9]+)?)$');
    final m = rx.firstMatch(t);
    return m == null ? null : double.tryParse(m.group(1)!);
  }

  double? _parseDistanceKm(String t) {
    // within:5km / <=5km / 5km
    final rx =
        RegExp(r'^(?:within|dist|d)?[:=<>]*\s*([0-9]+(?:\.[0-9]+)?)\s*km$');
    final m = rx.firstMatch(t);
    return m == null ? null : double.tryParse(m.group(1)!);
  }
}

// Extend with your set of types/synonyms
final Map<String, VenueType> _typeMap = {
  'club': VenueType.club,
  'bar': VenueType.bar,
  'pub': VenueType.pub,
  'beer_bar': VenueType.beer_bar,
  'cocktail_bar': VenueType.cocktail_bar,
  'gay_bar': VenueType.gay_bar,
  'wine_bar': VenueType.wine_bar,
  'sports_bar': VenueType.sports_bar,
  'karaoke_bar': VenueType.karaoke_bar,
  // enum names:
  for (final e in VenueType.values) describeEnum(e).toLowerCase(): e,
};

class _Spec {
  bool? openNow;
  bool? openToday;
  bool? verifiedOnly;
  int? minAge;
  double? minRating;
  double? maxPrice;
  double? maxDistanceKm;
  final Set<VenueType> types = {};
  final List<String> textTerms = [];
  LatLng? userLoc; // optional injection for distance
}
