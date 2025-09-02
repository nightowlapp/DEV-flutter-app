// lib/features/explore/search/search_filter.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/explore/search/search_controller.dart';
import 'package:nightowlcode/features/explore/search/search_query.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/utility/utility.dart'; // if you have title formatting; optional
import '../presentation/ranked_venues_controller.dart';

/// Pure function — can be reused in tests.
List<Venue> filterVenues(List<Venue> input, SearchQuery q) {
  if (q.isEmpty) return input;
  return input.where((v) => _matches(v, q)).toList(growable: false);
}

bool _matches(Venue v, SearchQuery q) {
  // Prepare searchable blob (normalized)
  final title = (v.displayName.isNotEmpty ? Utility.formatString(v.displayName) : Utility.formatString(v.name));
  final city  = v.city;
  final desc  = v.description;

  final haystack = _normalize('$title ${desc.isNotEmpty ? " $desc" : ""} ${city.isNotEmpty ? " $city" : ""}');

  // AND across tokens
  for (final term in q.terms) {
    if (!haystack.contains(term)) return false;
  }
  return true;
}

String _normalize(String s) {
  final lower = s.toLowerCase();
  final stripped = SearchQuery.removeDiacritics(lower);
  return stripped;
}


