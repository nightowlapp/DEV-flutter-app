import 'dart:math' as math;

import '../../../shared/utility/distance.dart';

class Geohash {
  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  static const _bits = [16, 8, 4, 2, 1];

  static String encode(double lat, double lon, int precision) {
    double minLat = -90, maxLat = 90, minLon = -180, maxLon = 180;
    bool evenBit = true;
    int bit = 0, ch = 0;
    final buffer = StringBuffer();

    while (buffer.length < precision) {
      if (evenBit) {
        final mid = (minLon + maxLon) / 2;
        if (lon >= mid) {
          ch |= _bits[bit];
          minLon = mid;
        } else {
          maxLon = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (lat >= mid) {
          ch |= _bits[bit];
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }
      evenBit = !evenBit;
      if (bit < 4) {
        bit++;
      } else {
        buffer.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return buffer.toString();
  }

  static double centerDistanceMeters(String a, String b) {
    final ca = _decodeCenter(a);
    final cb = _decodeCenter(b);
    return Distance.meters(ca.$1, ca.$2, cb.$1, cb.$2);
  }

  static (double, double) _decodeCenter(String hash) {
    double minLat = -90, maxLat = 90, minLon = -180, maxLon = 180;
    bool evenBit = true;
    for (final rune in hash.codeUnits) {
      final cd = _base32.indexOf(String.fromCharCode(rune));
      for (int n = 0; n < 5; n++) {
        final mask = _bits[n];
        if (evenBit) {
          final mid = (minLon + maxLon) / 2;
          if ((cd & mask) != 0) {
            minLon = mid;
          } else {
            maxLon = mid;
          }
        } else {
          final mid = (minLat + maxLat) / 2;
          if ((cd & mask) != 0) {
            minLat = mid;
          } else {
            maxLat = mid;
          }
        }
        evenBit = !evenBit;
      }
    }
    return ((minLat + maxLat) / 2, (minLon + maxLon) / 2);
  }

  static Set<String> coverCircle(
      double lat, double lon, double radiusKm, int precision) {
    final center = encode(lat, lon, precision);
    final cover = <String>{center, ..._neighbors(center)};

    // rough cell probe; expand if the circle is larger than ~one cell
    final center2 = encode(lat, lon + 0.05, precision);
    final cellMeters = centerDistanceMeters(center, center2).abs();
    if (radiusKm * 1000 > cellMeters * 1.5) {
      for (final h in List<String>.from(cover)) {
        cover.addAll(_neighbors(h));
      }
    }
    return cover;
  }

  static List<String> _neighbors(String hash) {
    final n = _adjacent(hash, 'n');
    final s = _adjacent(hash, 's');
    final e = _adjacent(hash, 'e');
    final w = _adjacent(hash, 'w');
    return [
      n,
      s,
      e,
      w,
      _adjacent(n, 'e'),
      _adjacent(n, 'w'),
      _adjacent(s, 'e'),
      _adjacent(s, 'w')
    ];
  }

  static const Map<String, List<String>> _borders = {
    'n': ['prxz', 'bcfguvyz'],
    's': ['028b', '0145hjnp'],
    'e': ['bcfguvyz', 'prxz'],
    'w': ['0145hjnp', '028b'],
  };

  static const Map<String, List<String>> _neighborsMap = {
    'n': [
      'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
      'bc01fg45238967deuvhjyznpkmstqrwx'
    ],
    's': [
      '14365h7k9dcfesgujnmqp0r2twvyx8zb',
      '238967debc01fg45kmstqrwxuvhjyznp'
    ],
    'e': [
      'bc01fg45238967deuvhjyznpkmstqrwx',
      'p0r21436x8zb9dcf5h7kjnmqesgutwvy'
    ],
    'w': [
      '238967debc01fg45kmstqrwxuvhjyznp',
      '14365h7k9dcfesgujnmqp0r2twvyx8zb'
    ],
  };

  /// Fixed: use neighbor.indexOf(last) to get an int, then take that char from _base32.
  static String _adjacent(String hash, String dir) {
    final last = hash[hash.length - 1];
    final type = (hash.length % 2) == 1 ? 0 : 1;
    final base = hash.substring(0, hash.length - 1);

    final border = _borders[dir]![type];
    final neighbor = _neighborsMap[dir]![type];

    final nextBase = (border.contains(last) && base.isNotEmpty)
        ? _adjacent(base, dir)
        : base;
    final idx = neighbor.indexOf(last);
    return nextBase + _base32[idx];
  }
}
