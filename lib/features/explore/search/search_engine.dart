// lib/features/explore/search/search_engine.dart
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/utility/distance.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/european_location_mapper.dart' as eu
    hide LatLng;

// ---------------------------------------------------------------------------
// Public provider
// ---------------------------------------------------------------------------

typedef NowInTz = DateTime Function(String? tzid);

/// Riverpod provider for the search engine.
final venueSearchEngineProvider =
    Provider.autoDispose<VenueSearchEngine>((ref) {
  // If you have a real tz resolver, inject it here. For now: device time.
  final nowInTz = (String? _) => DateTime.now();
  return VenueSearchEngine(nowInTz: nowInTz);
});

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

class VenueSearchEngine {
  VenueSearchEngine({required this.nowInTz});

  final NowInTz nowInTz;
  final eu.EuropeanLocationMapper _locMapper = eu.EuropeanLocationMapper();

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

  // -------------------------------------------------------------------------
  // TOKENIZATION / NORMALIZATION
  // -------------------------------------------------------------------------

  /// Split on whitespace but keep things like "4,2*", "21+" and "5km" intact.
  /// Also supports quoted phrases: "deep house" is treated as one term.
  List<String> _tokenize(String raw) {
    final norm = _normalize(raw);

    // Matches either "quoted phrase" OR bare non-space chunk
    final rx = RegExp(r'"([^"]+)"|(\S+)');
    final matches = rx.allMatches(norm);

    final out = <String>[];
    for (final m in matches) {
      final phrase = m.group(1);
      final token = m.group(2);
      final t = (phrase ?? token ?? '').trim();
      if (t.isNotEmpty) out.add(t);
    }
    return out;
  }

  // -------------------------------------------------------------------------
  // PARSING INTO SPEC
  // -------------------------------------------------------------------------

  _Spec _parse(List<String> tokens, {LatLng? userLoc}) {
    final spec = _Spec()..userLoc = userLoc;

    for (final raw in tokens) {
      final t = raw.trim();
      if (t.isEmpty) continue;

      // OPEN
      if (_openNowTerms.contains(t)) {
        spec.openNow = true;
        continue;
      }
      if (_openTodayTerms.contains(t)) {
        spec.openToday = true;
        continue;
      }

      // VERIFIED
      if (_verifiedTerms.contains(t)) {
        spec.verifiedOnly = true;
        continue;
      }

      // AGE: 18+, age:18, age>=18, a18+, 21+
      final age =
          _parseNumberWithPlus(t, prefixes: const ['age', 'a', 'alder']);
      if (age != null && age >= 10) {
        spec.minAge = age;
        continue;
      }

      // RATING: r:4.2, rating>=4, 4.5★, 4*, 4*+, 4+, 4,2*, 4,2
      final rating = _parseRating(t);
      if (rating != null) {
        spec.minRating = rating;
        continue;
      }

      // PRICE: price<=10 / p<=10 / €10 / $10 / 10kr
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

      // DISTANCE: within:5km / <=5km / 5km / 5,5km
      final distKm = _parseDistanceKm(t);
      if (distKm != null) {
        spec.maxDistanceKm = distKm;
        continue;
      }

      // otherwise → free text term (but expand basic synonyms like "klub")
      final synonym = _synonymMap[t];
      if (synonym != null) {
        spec.textTerms.add(synonym);
      } else {
        spec.textTerms.add(t);
      }
    }

    return spec;
  }

  // -------------------------------------------------------------------------
  // MATCHING
  // -------------------------------------------------------------------------

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
      final nameBlob = _normalize(
        '${v.displayName.isNotEmpty ? v.displayName : v.name} '
        '${v.city} '
        '${v.countryCode}',
      );

      for (final term in s.textTerms) {
        // exact substring in giant blob
        if (blob.contains(term)) continue;

        // fuzzy within names / city / tags
        if (_fuzzyMatchInText(term, nameBlob)) continue;

        // otherwise → no match
        return false;
      }
    }

    return true;
  }

  /// Big lowercase-then-folded blob of searchable fields.
  /// IMPORTANT: city/country & their synonyms come from EuropeanLocationMapper.
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
      // location (raw from venue)
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
      ..write(_ratingBlob(v))
      ..write(' ');

    // Enrich with location names from mapper (English city/country) + altNames
    try {
      final loc = _locMapper.resolve(
        lat: v.entry.lat,
        lon: v.entry.lng,
      );

      final country = loc.country;
      if (country != null) {
        sb
          ..write(country.name)
          ..write(' ');
        for (final alt in country.altNames) {
          sb
            ..write(alt)
            ..write(' ');
        }
      }

      final city = loc.city;
      if (city != null) {
        sb
          ..write(city.name)
          ..write(' ');
        for (final alt in city.altNames) {
          sb
            ..write(alt)
            ..write(' ');
        }
      }
    } catch (_) {
      // Mapper failures should never break search.
    }

    return _normalize(sb.toString());
  }

  String _ratingBlob(Venue v) {
    final rating = v.rating;
    if (rating == null) return '';
    final r1 = rating.toStringAsFixed(1); // "4.6"
    final r0 = rating.round().toString(); // "5"

    // Also add comma variants for European decimal-style searches
    final r1Comma = r1.replaceAll('.', ',');

    return '$r1 $r0 ${r1}* ${r0}* $r1Comma ${r1Comma}* ';
  }

  // -------------------------------------------------------------------------
  // HELPERS – parsing
  // -------------------------------------------------------------------------

  double? _parseRating(String t) {
    // Normalize decimal comma → dot so "4,2*" becomes "4.2*"
    var s = t.replaceAll(',', '.');

    // Strip star symbols first so "4*+", "4★" etc become "4+" / "4".
    s = s.replaceAll('★', '').replaceAll('*', '').trim();

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
    // Require a prefix (age|a|alder) OR a trailing plus (e.g., 18+).
    final s = t.toLowerCase().trim();
    final prefixRx = '(?:${prefixes.join('|')})';

    // age:18 / age>=18 / a18 / alder:18
    final m1 = RegExp('^$prefixRx[:=<>]*\\s*(\\d{1,2})(\\+)?\$').firstMatch(s);
    if (m1 != null) return int.tryParse(m1.group(1)!);

    // bare with plus: 18+
    final m2 = RegExp('^(\\d{1,2})\\+\$').firstMatch(s);
    if (m2 != null) return int.tryParse(m2.group(1)!);

    return null; // plain "18" or "80" is NOT age
  }

  VenueType? _parseType(String t) {
    final norm = _normalize(t);
    return _typeMap[norm];
  }

  double? _parsePriceMax(String t) {
    // Only parse if there's a price hint: prefix, currency symbol, or 'kr' suffix.
    var s = t.toLowerCase().replaceAll(',', '.').trim();

    // price<=10 / p:10 / pris 10
    final m1 = RegExp(
            r'^(?:price|pris|p)\s*(?:<=|=|:)?\s*([0-9]+(?:\.[0-9]+)?)\s*(?:kr)?$')
        .firstMatch(s);
    if (m1 != null) return double.tryParse(m1.group(1)!);

    // $10 or €10 (with optional comparator)
    final m2 = RegExp(r'^(?:<=|=|:)?\s*(?:€|\$)\s*([0-9]+(?:\.[0-9]+)?)\s*$')
        .firstMatch(s);
    if (m2 != null) return double.tryParse(m2.group(1)!);

    // 10kr (with optional comparator)
    final m3 =
        RegExp(r'^(?:<=|=|:)?\s*([0-9]+(?:\.[0-9]+)?)\s*kr$').firstMatch(s);
    if (m3 != null) return double.tryParse(m3.group(1)!);

    return null; // plain "80" becomes a text term
  }

  double? _parseDistanceKm(String t) {
    // within:5km / dist:5km / <=5km / 5km / 5,5km
    var s = t.toLowerCase();
    s = s.replaceAll(',', '.');

    final rx = RegExp(
      r'^(?:within|dist|distance|d)?[:=<>]*\s*([0-9]+(?:\.[0-9]+)?)\s*km$',
    );
    final m = rx.firstMatch(s);
    return m == null ? null : double.tryParse(m.group(1)!);
  }

  // -------------------------------------------------------------------------
  // HELPERS – fuzzy matching
  // -------------------------------------------------------------------------

  bool _fuzzyMatchInText(String term, String text) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);

    for (final w in words) {
      // fast exact
      if (w == term) return true;

      // skip wildly different lengths (optimization)
      final lenDiff = (w.length - term.length).abs();
      if (lenDiff > 2) continue;

      final dist = _levenshtein(term, w);

      // Cheap but effective thresholds:
      if (term.length <= 4) {
        if (dist <= 1) return true; // e.g. "klub" vs "club"
      } else if (dist <= 2) {
        return true; // e.g. "copenhagn" vs "copenhagen"
      }
    }
    return false;
  }

  int _levenshtein(String a, String b) {
    final la = a.length;
    final lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;

    final dp = List<List<int>>.generate(
      la + 1,
      (_) => List<int>.filled(lb + 1, 0),
    );

    for (var i = 0; i <= la; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= lb; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i <= la; i++) {
      for (var j = 1; j <= lb; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        dp[i][j] = math.min(
          math.min(
            dp[i - 1][j] + 1, // deletion
            dp[i][j - 1] + 1, // insertion
          ),
          dp[i - 1][j - 1] + cost, // substitution
        );
      }
    }
    return dp[la][lb];
  }
}

// ---------------------------------------------------------------------------
// SPEC
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// TYPE & TEXT SYNONYMS (non-location)
// ---------------------------------------------------------------------------

/// Extend with your set of types/synonyms.
/// All keys are expected to be pre-normalized via `_normalize`.
final Map<String, VenueType> _typeMap = {
  // Core English
  'club': VenueType.club,
  'clubs': VenueType.club,
  'nightclub': VenueType.club,
  'nightclubs': VenueType.club,
  'night club': VenueType.club,
  'night clubs': VenueType.club,
  'bar': VenueType.bar,
  'bars': VenueType.bar,
  'pub': VenueType.pub,
  'pubs': VenueType.pub,

  // Nordic & European synonyms for "club"
  'klub': VenueType.club,
  'klubb': VenueType.club,
  'clubben': VenueType.club,
  'diskotek': VenueType.club,
  'diskoteket': VenueType.club,
  'discoteca': VenueType.club,
  'discoteque': VenueType.club,
  'discotheque': VenueType.club,
  'disco': VenueType.club,
  'natklub': VenueType.club,
  'natklubb': VenueType.club,
  'nightlife': VenueType.club,

  // "bar" variants
  'barer': VenueType.bar,
  'barerne': VenueType.bar,
  'bierbar': VenueType.beer_bar,
  'ølbar': VenueType.beer_bar,
  'beerbar': VenueType.beer_bar,

  // Specific bar subtypes
  'beer_bar': VenueType.beer_bar,
  'beer bar': VenueType.beer_bar,
  'cocktail_bar': VenueType.cocktail_bar,
  'cocktail bar': VenueType.cocktail_bar,
  'cocktailbar': VenueType.cocktail_bar,
  'gay_bar': VenueType.gay_bar,
  'gay bar': VenueType.gay_bar,
  'gaybar': VenueType.gay_bar,
  'wine_bar': VenueType.wine_bar,
  'wine bar': VenueType.wine_bar,
  'winebar': VenueType.wine_bar,
  'sports_bar': VenueType.sports_bar,
  'sports bar': VenueType.sports_bar,
  'sportsbar': VenueType.sports_bar,
  'karaoke_bar': VenueType.karaoke_bar,
  'karaoke bar': VenueType.karaoke_bar,
  'karaokebar': VenueType.karaoke_bar,
  'karaoke': VenueType.karaoke_bar,

  // Enum names as fallback (covers everything else)
  for (final e in VenueType.values) describeEnum(e).toLowerCase(): e,
};

/// Generic non-location text synonyms – these are applied to *tokens* before
/// matching. Keep location synonyms (city/country) in the mapper via altNames.
final Map<String, String> _synonymMap = {
  // Types
  'klub': 'club',
  'klubb': 'club',
  'diskotek': 'club',
  'diskoteket': 'club',
  'disco': 'club',
  'natklub': 'club',
  'natklubb': 'club',
  'ølbar': 'beer bar',
  'beerbar': 'beer bar',
};

// ---------------------------------------------------------------------------
// Simple keyword sets
// ---------------------------------------------------------------------------

final Set<String> _openNowTerms = {
  'open',
  'opennow',
  'now',
  'åben',
  'åbent',
  'nu',
};

final Set<String> _openTodayTerms = {
  'opentoday',
  'today',
  'idag',
  'i dag',
};

final Set<String> _verifiedTerms = {
  'verified',
  'official',
  'verificeret',
};

// ---------------------------------------------------------------------------
// NORMALIZATION / DIACRITIC FOLDING
// ---------------------------------------------------------------------------

/// Aggressive normalization:
/// - lowercases
/// - strips / folds diacritics: 'ø' → 'o', 'å' → 'a', 'ä' → 'a', 'é' → 'e', ...
/// - collapses whitespace
/// - keeps digits & useful symbols (.,+*#:@) for parsing
String _normalize(String input) {
  if (input.isEmpty) return '';

  final sb = StringBuffer();
  bool lastWasSpace = false;

  for (final rune in input.runes) {
    var ch = String.fromCharCode(rune);
    ch = ch.toLowerCase();

    final mapped = _foldChar(ch);
    if (mapped == ' ') {
      if (!lastWasSpace) {
        sb.write(' ');
        lastWasSpace = true;
      }
    } else {
      sb.write(mapped);
      lastWasSpace = false;
    }
  }

  return sb.toString().trim();
}

/// Map a single character into its ASCII-ish representation.
String _foldChar(String ch) {
  // Letters & digits we want to keep as is
  final code = ch.codeUnitAt(0);
  if (code >= 0x30 && code <= 0x39) return ch; // 0-9
  if (code >= 0x61 && code <= 0x7a) return ch; // a-z

  // Common symbols we want to keep for tokens like "4.2*", "5km", "#techno"
  const keep = '.:,;+*#@%/=<>+-_';
  if (keep.contains(ch)) return ch;

  // Whitespace-like
  if (RegExp(r'\s').hasMatch(ch)) return ' ';

  // Nordic / European diacritics – feel free to expand
  switch (ch) {
    case 'æ':
      return 'ae';
    case 'ø':
      return 'o';
    case 'å':
      return 'a';
    case 'ä':
    case 'á':
    case 'à':
    case 'â':
    case 'ã':
      return 'a';
    case 'ö':
    case 'ó':
    case 'ò':
    case 'ô':
    case 'õ':
      return 'o';
    case 'ü':
    case 'ú':
    case 'ù':
    case 'û':
      return 'u';
    case 'é':
    case 'è':
    case 'ê':
    case 'ë':
      return 'e';
    case 'í':
    case 'ì':
    case 'î':
    case 'ï':
      return 'i';
    case 'ç':
      return 'c';
    case 'ß':
      return 'ss';
  }

  // Everything else -> space (separates words)
  return ' ';
}
