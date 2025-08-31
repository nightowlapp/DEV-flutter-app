import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class Utility {
  static String formatString(String input) {
    // Replace underscores, hyphens with space
    input = input.replaceAll(RegExp(r'[_\-]+'), ' ');
    // Insert space before capital letters (for camelCase or PascalCase)
    input = input.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
    );
    // Normalize whitespaces
    input = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Split and capitalize
    return input
        .split(' ')
        .map((word) => _capitalize(word))
        .join(' ');
  }
  static String _capitalize(String word) {
    if (word.isEmpty) return '';
    if (word.toUpperCase() == word) return word; // Keep acronyms
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }


  static const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const months = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  static String dayShort(DateTime d) => days[(d.weekday - 1) % 7];
  static String monthShort(DateTime d) => months[d.month - 1];
  static String _two(int n) => n < 10 ? '0$n' : '$n';
  static String hhmm(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}';







}


/// Call [TzUtils.ensureInitialized()] once at app start.
class TzUtils {
  static bool _inited = false;

  /// Load time zone database once.
  static void ensureInitialized() {
    if (_inited) return;
    tzdata.initializeTimeZones();
    _inited = true;
  }

  /// Returns "now" in the given IANA zone.
  /// Falls back to device local time if tzid is null/empty/unknown.
  static DateTime nowIn(String? tzid) {
    try {
      if (tzid == null || tzid.isEmpty) return DateTime.now();
      final loc = tz.getLocation(tzid);
      return tz.TZDateTime.now(loc);
    } catch (_) {
      // Unknown tz id → fallback gracefully
      return DateTime.now();
    }
  }

  /// Convert an absolute [moment] to the given zone (keeps the same instant).
  /// Works for both UTC and local DateTimes.
  static DateTime toZone(DateTime moment, String? tzid) {
    try {
      if (tzid == null || tzid.isEmpty) return moment;
      final loc = tz.getLocation(tzid);
      return tz.TZDateTime.from(moment, loc);
    } catch (_) {
      return moment;
    }
  }

  /// Format a date-only (YYYY-MM-DD) in a given zone from an absolute instant.
  static String ymdIn(DateTime moment, String? tzid) {
    final z = toZone(moment, tzid);
    final mm = z.month.toString().padLeft(2, '0');
    final dd = z.day.toString().padLeft(2, '0');
    return '${z.year}-$mm-$dd';
  }
}










