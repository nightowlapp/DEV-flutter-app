// lib/features/explore/search/search_engine.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/utility/distance.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

typedef NowInTz = DateTime Function(String? tzid);

/// Riverpod provider for the search engine.
final venueSearchEngineProvider =
Provider.autoDispose<VenueSearchEngine>((ref) {
  // If you have a real tz resolver, inject it here. For now: device time.
  final nowInTz = (String? _) => DateTime.now();
  return VenueSearchEngine(nowInTz: nowInTz);
});

class VenueSearchEngine {
  VenueSearchEngine({required this.nowInTz});

  final NowInTz nowInTz;

  /// Main entry:
  ///
  /// - `query` is the raw text from the search bar (e.g. "club 21+ 4* open").
  /// - `userLoc` is optional, but enables distance tokens like "5km".
  List<Venue> filter(
      List<Venue> input,
      String query, {
        LatLng? userLoc,
      }) {
    final q = query.trim();
    if (q.isEmpty) return input;

    final tokens = _tokenize(q);
    if (tokens.isEmpty) return input;

    final spec = _parse(tokens, userLoc: userLoc);
    return input.where((v) => _matches(v, spec)).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // TOKENIZATION / NORMALIZATION
  // ---------------------------------------------------------------------------

  List<String> _tokenize(String raw) {
    final norm = _normalize(raw);
    return norm.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  String _normalize(String s) => s.toLowerCase(); // simple, ASCII-safe

  // ---------------------------------------------------------------------------
  // PARSING INTO SPEC
  // ---------------------------------------------------------------------------

  _Spec _parse(List<String> tokens, {LatLng? userLoc}) {
    final spec = _Spec()..userLoc = userLoc;

    for (final raw in tokens) {
      final t = raw.trim();
      if (t.isEmpty) continue;

      // OPEN
      if (t == 'open' || t == 'opennow' || t == 'now') {
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

      // AGE: 18+, age:18, age>=18, a18+, 21+
      final age = _parseNumberWithPlus(t, prefixes: const ['age', 'a']);
      if (age != null && age >= 10) {
        spec.minAge = age;
        continue;
      }

      // RATING: r:4.2, rating>=4, 4.5★, 4*, 4*+, 4+
      final rating = _parseRating(t);
      if (rating != null) {
        spec.minRating = rating;
        continue;
      }

      // PRICE: price<=10 / p<=10 / €10 / $10
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

      // DISTANCE: within:5km / <=5km / 5km
      final distKm = _parseDistanceKm(t);
      if (distKm != null) {
        spec.maxDistanceKm = distKm;
        continue;
      }

      // otherwise → free text term
      spec.textTerms.add(t);
    }

    return spec;
  }

  // ---------------------------------------------------------------------------
  // MATCHING
  // ---------------------------------------------------------------------------

  bool _matches(Venue v, _Spec s) {
    final now = nowInTz(v.timeZoneId);

    // OPEN
    if (s.openNow == true && !v.isOpenNow(now)) return false;
    if (s.openToday == true && !v.isOpenToday(now)) return false;

    // VERIFIED
    if (s.verifiedOnly == true && !v.isVerified) return false;

    // AGE (effective)
    if (s.minAge != null) {
      final effAge = v.effectiveAgeRestriction(now);
      if (effAge < s.minAge!) return false;
    }

    // RATING
    if (s.minRating != null) {
      final r = v.rating ?? 0;
      if (r < s.minRating!) return false;
    }

    // PRICE
    if (s.maxPrice != null) {
      final price = v.effectiveEntryPrice(now);
      if (price > s.maxPrice!) return false;
    }

    // TYPE
    if (s.types.isNotEmpty && !s.types.contains(v.type)) return false;

    // DISTANCE
    if (s.maxDistanceKm != null && s.userLoc != null) {
      final meters = Distance.metersLatLng(s.userLoc!, v.entry);
      if (meters > s.maxDistanceKm! * 1000.0) return false;
    }

    // TEXT: name / alt name / desc / city / country / tags / misc
    if (s.textTerms.isNotEmpty) {
      final blob = _buildTextBlob(v);
      for (final term in s.textTerms) {
        if (!blob.contains(term)) return false;
      }
    }

    return true;
  }

  /// Big lowercase blob of searchable fields.
  String _buildTextBlob(Venue v) {
    final displayName =
    (v.displayName.isNotEmpty ? v.displayName : v.name).trim();

    final sb = StringBuffer()
    // names
      ..write(displayName)
      ..write(' ')
      ..write(v.name)
      ..write(' ')
    // description
      ..write(v.description)
      ..write(' ')
    // location
      ..write(v.city)
      ..write(' ')
      ..write(v.countryCode)
      ..write(' ')
    // identity / misc
      ..write(v.companyNumber ?? '')
      ..write(' ')
      ..write(v.email ?? '')
      ..write(' ')
      ..write(v.phone ?? '')
      ..write(' ')
    // type & dress code & subscription
      ..write(describeEnum(v.type))
      ..write(' ')
      ..write(describeEnum(v.defaultDressCode))
      ..write(' ')
      ..write(subscriptionTypeToString(v.subscriptionType))
      ..write(' ')
    // tags
      ..write(v.tagids.join(' '))
      ..write(' ')
    // age forms
      ..write(v.defaultAgeRestriction.toString())
      ..write(' ')
      ..write('${v.defaultAgeRestriction}+ ')
    // rating forms
      ..write(_ratingBlob(v));

    return _normalize(sb.toString());
  }

  String _ratingBlob(Venue v) {
    final rating = v.rating;
    if (rating == null) return '';
    final r1 = rating.toStringAsFixed(1); // "4.6"
    final r0 = rating.round().toString(); // "5"
    return '$r1 $r0 ${r1}* ${r0}* ';
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  double? _parseRating(String t) {
    // Strip star symbols first so "4*+", "4★" etc become "4+" / "4".
    var s = t.replaceAll('★', '').replaceAll('*', '').trim();

    // rating:4.2 / r:4 / rating>=4 / r>=4
    final p = RegExp(r'^(r|rating)[:=<>]*\s*([0-5](?:\.\d)?)$');
    final m = p.firstMatch(s);
    if (m != null) return double.tryParse(m.group(2)!);

    // 4.5+ or >=4 (plus is "at least")
    final p2 = RegExp(r'^(?:>=)?([0-5](?:\.\d)?)(\+)?$');
    final m2 = p2.firstMatch(s);
    if (m2 != null) return double.tryParse(m2.group(1)!);

    return null;
  }

  int? _parseNumberWithPlus(String t, {required List<String> prefixes}) {
    // age:18+, age>=18, 18+, 21+
    final prefixRx = prefixes.isEmpty ? '' : '(?:${prefixes.join('|')})';
    final rx = RegExp('^(?:$prefixRx)?[:=<>]*\\s*(\\d{1,2})(\\+)?\$');
    final m = rx.firstMatch(t);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  VenueType? _parseType(String t) {
    final norm = _normalize(t);
    return _typeMap[norm];
  }

  double? _parsePriceMax(String t) {
    // price<=10 / p<=10 / €10 / $10
    final rx = RegExp(
      r'^(?:price|p)?\s*(?:<=|=|:)?\s*(?:€|\$)?\s*([0-9]+(?:\.[0-9]+)?)$',
    );
    final m = rx.firstMatch(t);
    return m == null ? null : double.tryParse(m.group(1)!);
  }

  double? _parseDistanceKm(String t) {
    // within:5km / dist:5km / <=5km / 5km
    final rx = RegExp(
      r'^(?:within|dist|d)?[:=<>]*\s*([0-9]+(?:\.[0-9]+)?)\s*km$',
    );
    final m = rx.firstMatch(t);
    return m == null ? null : double.tryParse(m.group(1)!);
  }
}

// Extend with your set of types/synonyms
final Map<String, VenueType> _typeMap = {
  // Plain words
  'club': VenueType.club,
  'clubs': VenueType.club,
  'nightclub': VenueType.club,
  'nightclubs': VenueType.club,
  'bar': VenueType.bar,
  'bars': VenueType.bar,
  'pub': VenueType.pub,
  'pubs': VenueType.pub,

  // Specific bar subtypes
  'beer_bar': VenueType.beer_bar,
  'beer bar': VenueType.beer_bar,
  'cocktail_bar': VenueType.cocktail_bar,
  'cocktail bar': VenueType.cocktail_bar,
  'gay_bar': VenueType.gay_bar,
  'gay bar': VenueType.gay_bar,
  'wine_bar': VenueType.wine_bar,
  'wine bar': VenueType.wine_bar,
  'sports_bar': VenueType.sports_bar,
  'sports bar': VenueType.sports_bar,
  'karaoke_bar': VenueType.karaoke_bar,
  'karaoke bar': VenueType.karaoke_bar,
  'karaoke': VenueType.karaoke_bar,
  //TODO improve with all kinds of search - "københavn" and so on.

  // Enum names as fallback (covers everything else)
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
  LatLng? userLoc;
}
