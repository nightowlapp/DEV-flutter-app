// lib/features/explore/search/search_query.dart
import 'dart:collection';

class SearchQuery {
  final String raw;
  final List<String> terms; // normalized tokens

  const SearchQuery._(this.raw, this.terms);
  const SearchQuery.empty() : this._('', const []);

  bool get isEmpty => terms.isEmpty && raw.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  factory SearchQuery.fromRaw(String raw) {
    final norm = _normalize(raw);
    final ts = _tokenize(norm);
    return SearchQuery._(raw, UnmodifiableListView(ts));
  }

  static String _normalize(String s) =>
      removeDiacritics(s.toLowerCase()).replaceAll(RegExp(r'\s+'), ' ').trim();

  // Keep letters/digits and these symbols we parse: + . : > <
  // Everything else becomes space, then split on whitespace.
  static List<String> _tokenize(String s) {
    if (s.isEmpty) return const [];
    final cleaned = s.replaceAll(RegExp(r'[^a-z0-9+\.\:><]+'), ' ').trim();
    return cleaned.isEmpty ? const [] : cleaned.split(RegExp(r'\s+'));
  }

  /// Public helper (used by other files) — lightweight diacritics strip.
  static String removeDiacritics(String input) {
    if (input.isEmpty) return input;
    const map = {
      'à':'a','á':'a','â':'a','ã':'a','ä':'a','å':'a','ă':'a','ą':'a','ā':'a',
      'ç':'c','ć':'c','č':'c',
      'đ':'d','ď':'d',
      'è':'e','é':'e','ê':'e','ë':'e','ě':'e','ė':'e','ę':'e','ē':'e',
      'ì':'i','í':'i','î':'i','ï':'i','ı':'i','į':'i','ī':'i',
      'ľ':'l','ĺ':'l','ł':'l',
      'ñ':'n','ň':'n','ń':'n',
      'ò':'o','ó':'o','ô':'o','õ':'o','ö':'o','ő':'o','ō':'o',
      'ř':'r','ŕ':'r',
      'š':'s','ś':'s','ș':'s','ß':'ss',
      'ť':'t','ț':'t',
      'ù':'u','ú':'u','û':'u','ü':'u','ű':'u','ū':'u',
      'ý':'y','ÿ':'y',
      'ž':'z','ź':'z','ż':'z',
      // Uppercase
      'À':'A','Á':'A','Â':'A','Ã':'A','Ä':'A','Å':'A','Ă':'A','Ą':'A','Ā':'A',
      'Ç':'C','Ć':'C','Č':'C',
      'Đ':'D','Ď':'D',
      'È':'E','É':'E','Ê':'E','Ë':'E','Ě':'E','Ė':'E','Ę':'E','Ē':'E',
      'Ì':'I','Í':'I','Î':'I','Ï':'I','İ':'I','Į':'I','Ī':'I',
      'Ľ':'L','Ĺ':'L','Ł':'L',
      'Ñ':'N','Ň':'N','Ń':'N',
      'Ò':'O','Ó':'O','Ô':'O','Õ':'O','Ö':'O','Ő':'O','Ō':'O',
      'Ř':'R','Ŕ':'R',
      'Š':'S','Ś':'S','Ș':'S',
      'Ť':'T','Ț':'T',
      'Ù':'U','Ú':'U','Û':'U','Ü':'U','Ű':'U','Ū':'U',
      'Ý':'Y',
      'Ž':'Z','Ź':'Z','Ż':'Z',
    };
    final buf = StringBuffer();
    for (final ch in input.runes) {
      final s = String.fromCharCode(ch);
      buf.write(map[s] ?? s);
    }
    return buf.toString();
  }
}
