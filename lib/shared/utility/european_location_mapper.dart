// european_location_mapper.dart
import 'dart:math' as math;

/// Simple lat/lon.
class LatLng {
  final double lat;
  final double lon;
  const LatLng(this.lat, this.lon);
}

/// Axis-aligned bounding box.
class BoundingBox {
  final double minLat, minLon, maxLat, maxLon;
  const BoundingBox({
    required this.minLat,
    required this.minLon,
    required this.maxLat,
    required this.maxLon,
  });

  /// Helper to build from [minLon, minLat, maxLon, maxLat] arrays (like your seed).
  factory BoundingBox.fromLonLat({
    required double minLon,
    required double minLat,
    required double maxLon,
    required double maxLat,
  }) => BoundingBox(minLat: minLat, minLon: minLon, maxLat: maxLat, maxLon: maxLon);

  bool contains(double lat, double lon) =>
      lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
}

class CountryInfo {
  final String code; // ISO-2
  final String name;
  final BoundingBox bbox;
  const CountryInfo({required this.code, required this.name, required this.bbox});

  bool contains(double lat, double lon) => bbox.contains(lat, lon);
}

class CityInfo {
  final String name;
  final String countryCode; // ISO-2
  final LatLng center;
  final BoundingBox bbox;
  const CityInfo({
    required this.name,
    required this.countryCode,
    required this.center,
    required this.bbox,
  });

  bool contains(double lat, double lon) => bbox.contains(lat, lon);
}

class LocationResult {
  final CountryInfo? country;
  final CityInfo? city;
  const LocationResult({this.country, this.city});

  String? get countryCode => country?.code;
  String? get countryName => country?.name;
  String? get cityName => city?.name;

  @override
  String toString() => 'LocationResult(country: ${country?.code}/${country?.name}, city: ${city?.name})';
}

class EuropeanLocationMapper {
  EuropeanLocationMapper();


  Map<String, CountryInfo> get countries =>
      {for (final c in _countries) c.code: c};

  List<CityInfo> citiesInCountry(String iso2) =>
      List.unmodifiable(_citiesByCountry[iso2.toUpperCase()] ?? const []);


  // ----------------- Public API -----------------

  /// Resolve both country and city for a given coordinate.
  /// [maxCityFallbackKm] is used if the point is inside the country
  /// but outside any city's bbox: we pick the nearest city (center distance)
  /// if it's within this radius; otherwise city will be null.
  LocationResult resolve({required double lat, required double lon, double maxCityFallbackKm = 60}) {
    final country = findCountry(lat, lon);
    CityInfo? city;

    if (country != null) {
      final cityList = _citiesByCountry[country.code] ?? const <CityInfo>[];
      final matches = cityList.where((c) => c.contains(lat, lon)).toList();

      if (matches.isNotEmpty) {
        city = (matches.length == 1) ? matches.first : closestByCenter(matches, lat, lon);
      } else {
        city = nearestCityWithin(country.code, lat, lon, maxCityFallbackKm);
      }
    }
    return LocationResult(country: country, city: city);
  }

  /// Resolve just the country.
  CountryInfo? resolveCountry(double lat, double lon) => findCountry(lat, lon);

  /// Resolve just the city (with same fallback behavior). Country must be resolvable.
  CityInfo? resolveCity(double lat, double lon, {double maxCityFallbackKm = 60}) {
    final r = resolve(lat: lat, lon: lon, maxCityFallbackKm: maxCityFallbackKm);
    return r.city;
  }

  // ----------------- Internals -----------------

  CountryInfo? findCountry(double lat, double lon) {
    // Fast bbox scan; Europe list is small.
    for (final c in _countries) {
      if (c.contains(lat, lon)) return c;
    }
    return null;
  }

  CityInfo? closestByCenter(List<CityInfo> list, double lat, double lon) {
    CityInfo? best;
    var bestD = double.infinity;
    for (final c in list) {
      final d = _haversineKm(lat, lon, c.center.lat, c.center.lon);
      if (d < bestD) {
        bestD = d;
        best = c;
      }
    }
    return best;
  }

  CityInfo? nearestCityWithin(String countryCode, double lat, double lon, double maxKm) {
    final cities = _citiesByCountry[countryCode];
    if (cities == null || cities.isEmpty) return null;
    CityInfo? best;
    var bestD = double.infinity;
    for (final c in cities) {
      final d = _haversineKm(lat, lon, c.center.lat, c.center.lon);
      if (d < bestD) {
        bestD = d;
        best = c;
      }
    }
    return (bestD <= maxKm) ? best : null;
  }

  // Great-circle distance.
  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0088; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double d) => d * math.pi / 180.0;

  // ----------------- Data -----------------

  // Countries (bbox from your seed: [minLon, minLat, maxLon, maxLat])
  static final List<CountryInfo> _countries = [
    _c('AL', 'Albania',   19.16, 39.64, 21.03, 42.67),
    _c('AD', 'Andorra',    1.47, 42.46,  1.71, 42.64),
    _c('AM', 'Armenia',   43.58, 38.74, 46.51, 41.25),
    _c('AT', 'Austria',    9.55, 46.37, 17.15, 49.02),
    _c('BY', 'Belarus',   23.18, 51.29, 32.77, 56.17),
    _c('BE', 'Belgium',    2.47, 49.49,  6.37, 51.51),
    _c('BA', 'Bosnia',    15.75, 42.56, 19.62, 45.26),
    _c('BG', 'Bulgaria',  22.36, 41.25, 28.61, 44.23),
    _c('HR', 'Croatia',   13.19, 42.37, 19.44, 46.51),
    _c('CY', 'Cyprus',    32.27, 34.58, 34.59, 35.72),
    _c('CZ', 'Czech Republic', 12.09, 48.55, 18.86, 51.05),
    _c('DK', 'Denmark',    8.06, 54.53, 15.17, 57.75),
    _c('EE', 'Estonia',   21.76, 57.49, 28.22, 59.54),
    _c('FI', 'Finland',   19.09, 59.79, 31.58, 70.10),
    _c('FR', 'France',    -5.11, 42.34,  9.54, 51.09),
    _c('GE', 'Georgia',   39.75, 41.04, 46.67, 43.55),
    _c('DE', 'Germany',    5.86, 47.27, 15.04, 54.83),
    _c('GR', 'Greece',    19.38, 34.81, 28.23, 41.75),
    _c('HU', 'Hungary',   16.21, 45.75, 22.56, 48.59),
    _c('IS', 'Iceland',  -24.54, 63.39,-13.04, 66.54),
    _c('IE', 'Ireland',  -10.48, 51.44, -6.03, 55.34),
    _c('IT', 'Italy',      6.62, 36.63, 18.52, 47.09),
    _c('XK', 'Kosovo',    20.09, 41.99, 21.69, 43.09),
    _c('LV', 'Latvia',    20.99, 55.68, 28.22, 57.99),
    _c('LI', 'Liechtenstein', 9.48, 47.02, 9.62, 47.21),
    _c('LT', 'Lithuania', 20.99, 53.89, 26.59, 56.44),
    _c('LU', 'Luxembourg', 5.73, 49.42, 6.55, 50.19),
    _c('MT', 'Malta',     14.25, 35.83, 14.59, 36.08),
    _c('MD', 'Moldova',   26.61, 45.41, 30.17, 48.48),
    _c('MC', 'Monaco',     7.41, 43.73,  7.42, 43.74),
    _c('ME', 'Montenegro',18.41, 41.83, 20.27, 43.52),
    _c('NL', 'Netherlands', 3.22, 50.75, 7.22, 53.55),
    _c('MK', 'North Macedonia', 20.45, 40.85, 23.00, 42.33),
    _c('NO', 'Norway',     4.09, 57.99, 31.33, 71.19),
    _c('PL', 'Poland',    14.12, 49.00, 24.15, 54.83),
    _c('PT', 'Portugal',  -9.55, 36.95, -6.19, 42.16),
    _c('RO', 'Romania',   20.25, 43.62, 29.68, 48.27),
    _c('RU', 'Russia',    19.66, 41.15,180.00, 81.34),
    _c('SM', 'San Marino',12.44, 43.93, 12.46, 43.96),
    _c('RS', 'Serbia',    18.79, 42.22, 22.96, 46.18),
    _c('SK', 'Slovakia',  16.84, 47.72, 22.57, 49.59),
    _c('SI', 'Slovenia',  13.38, 45.43, 16.59, 46.88),
    _c('ES', 'Spain',     -9.29, 35.86,  4.31, 43.75),
    _c('SE', 'Sweden',    11.00, 55.34, 23.99, 69.04),
    _c('CH', 'Switzerland', 5.96, 45.82, 10.49, 47.81),
    _c('TR', 'Turkey',    25.99, 35.82, 44.82, 42.32),
    _c('UA', 'Ukraine',   22.15, 44.21, 40.03, 52.25),
    _c('GB', 'United Kingdom', -8.61, 49.87, 1.76, 58.64),
  ];

  // Helper for countries.
  static CountryInfo _c(String code, String name, double minLon, double minLat, double maxLon, double maxLat) {
    return CountryInfo(
      code: code,
      name: name,
      bbox: BoundingBox.fromLonLat(minLon: minLon, minLat: minLat, maxLon: maxLon, maxLat: maxLat),
    );
  }

  // ---- Cities (subset from your seed; extend as needed) ----
  static final Map<String, List<CityInfo>> _citiesByCountry = {
    'DK': [
      _city('Copenhagen','DK', 55.6761, 12.5683, 12.3683, 55.4761, 12.7683, 55.8761),
      _city('Aarhus',    'DK', 56.1567, 10.2107, 10.0107, 55.9567, 10.4107, 56.3567),
      _city('Odense',    'DK', 55.4038, 10.4024, 10.2024, 55.2038, 10.6024, 55.6038),
      _city('Aalborg',   'DK', 57.0488,  9.9217,  9.7217, 56.8488, 10.1217, 57.2488),
      _city('Esbjerg',   'DK', 55.4765,  8.4594,  8.2594, 55.2765,  8.6594, 55.6765),
      _city('Randers',   'DK', 56.4606, 10.0365,  9.8365, 56.2606, 10.2365, 56.6606),
      _city('Horsens',   'DK', 55.8607,  9.8503,  9.6503, 55.6607, 10.0503, 56.0607),
      _city('Kolding',   'DK', 55.4960,  9.4731,  9.2731, 55.2960,  9.6731, 55.6960),
      _city('Vejle',     'DK', 55.7113,  9.5359,  9.3359, 55.5113,  9.7359, 55.9113),
      _city('Roskilde',  'DK', 55.6419, 12.0805, 11.8805, 55.4419, 12.2805, 55.8419),
      _city('Silkeborg', 'DK', 56.1697,  9.5451,  9.3451, 55.9697,  9.7451, 56.3697),
      _city('Herning',   'DK', 56.1393,  8.9738,  8.7738, 55.9393,  9.1738, 56.3393),
      _city('Helsingor', 'DK', 56.0308, 12.5921, 12.3921, 55.8308, 12.7921, 56.2308),
      _city('Naestved',  'DK', 55.2299, 11.7609, 11.5609, 55.0299, 11.9609, 55.4299),
      _city('Viborg',    'DK', 56.4532,  9.4020,  9.2020, 56.2532,  9.6020, 56.6532),
      _city('Fredericia','DK', 55.5657,  9.7526,  9.5526, 55.3657,  9.9526, 55.7657),
      _city('Koge',      'DK', 55.4575, 12.1821, 11.9821, 55.2575, 12.3821, 55.6575),
      _city('Taastrup',  'DK', 55.6460, 12.2979, 12.0979, 55.4460, 12.4979, 55.8460),
      _city('Holstebro', 'DK', 56.3626,  8.6212,  8.4212, 56.1626,  8.8212, 56.5626),
      _city('Hillerod',  'DK', 55.9279, 12.3008, 12.1008, 55.7279, 12.5008, 56.1279),
      _city('Slagelse',  'DK', 55.4021, 11.3516, 11.1516, 55.2021, 11.5516, 55.6021),
      _city('Holbaek',   'DK', 55.7147, 11.7176, 11.5176, 55.5147, 11.9176, 55.9147),
    ],
    // ---------------- SWEDEN (SE) ----------------
    'SE': [
      _city('Stockholm','SE', 59.3293, 18.0686, 17.8686, 59.1293, 18.2686, 59.5293),
      _city('Gothenburg','SE', 57.7089, 11.9746, 11.7746, 57.5089, 12.1746, 57.9089),
      _city('Malmo','SE', 55.6050, 13.0038, 12.8038, 55.4050, 13.2038, 55.8050),
      _city('Uppsala','SE', 59.8586, 17.6389, 17.4389, 59.6586, 17.8389, 60.0586),
      _city('Vasteras','SE', 59.6099, 16.5448, 16.3448, 59.4099, 16.7448, 59.8099),
      _city('Orebro','SE', 59.2753, 15.2134, 15.0134, 59.0753, 15.4134, 59.4753),
      _city('Linkoping','SE', 58.4108, 15.6214, 15.4214, 58.2108, 15.8214, 58.6108),
      _city('Helsingborg','SE', 56.0465, 12.6945, 12.4945, 55.8465, 12.8945, 56.2465),
      _city('Jonkoping','SE', 57.7815, 14.1562, 13.9562, 57.5815, 14.3562, 57.9815),
      _city('Norrkoping','SE', 58.5877, 16.1924, 15.9924, 58.3877, 16.3924, 58.7877),
      _city('Lund','SE', 55.7047, 13.1910, 12.9910, 55.5047, 13.3910, 55.9047),
      _city('Umea','SE', 63.8258, 20.2630, 20.0630, 63.6258, 20.4630, 64.0258),
      _city('Gavle','SE', 60.6749, 17.1413, 16.9413, 60.4749, 17.3413, 60.8749),
      _city('Boras','SE', 57.7210, 12.9401, 12.7401, 57.5210, 13.1401, 57.9210),
      _city('Eskilstuna','SE', 59.3713, 16.5098, 16.3098, 59.1713, 16.7098, 59.5713),
      _city('Sodertalje','SE', 59.1955, 17.6253, 17.4253, 58.9955, 17.8253, 59.3955),
      _city('Karlstad','SE', 59.3793, 13.5036, 13.3036, 59.1793, 13.7036, 59.5793),
      _city('Halmstad','SE', 56.6745, 12.8568, 12.6568, 56.4745, 13.0568, 56.8745),
      _city('Vaxjo','SE', 56.8790, 14.8059, 14.6059, 56.6790, 15.0059, 57.0790),
      _city('Sundsvall','SE', 62.3908, 17.3069, 17.1069, 62.1908, 17.5069, 62.5908),
    ],

    // ---------------- FINLAND (FI) ----------------
    'FI': [
      _city('Helsinki','FI', 60.1699, 24.9384, 24.7384, 59.9699, 25.1384, 60.3699),
      _city('Espoo','FI', 60.2055, 24.6559, 24.4559, 60.0055, 24.8559, 60.4055),
      _city('Tampere','FI', 61.4978, 23.7610, 23.5610, 61.2978, 23.9610, 61.6978),
      _city('Vantaa','FI', 60.2934, 25.0378, 24.8378, 60.0934, 25.2378, 60.4934),
      _city('Oulu','FI', 65.0121, 25.4651, 25.2651, 64.8121, 25.6651, 65.2121),
      _city('Turku','FI', 60.4518, 22.2666, 22.0666, 60.2518, 22.4666, 60.6518),
      _city('Jyvaskyla','FI', 62.2415, 25.7209, 25.5209, 62.0415, 25.9209, 62.4415),
      _city('Kuopio','FI', 62.8924, 27.6770, 27.4770, 62.6924, 27.8770, 63.0924),
      _city('Lahti','FI', 60.9827, 25.6615, 25.4615, 60.7827, 25.8615, 61.1827),
      _city('Pori','FI', 61.4850, 21.7970, 21.5970, 61.2850, 21.9970, 61.6850),
      _city('Kouvola','FI', 60.8674, 26.7043, 26.5043, 60.6674, 26.9043, 61.0674),
      _city('Joensuu','FI', 62.6010, 29.7634, 29.5634, 62.4010, 29.9634, 62.8010),
      _city('Lappeenranta','FI', 61.0583, 28.1887, 27.9887, 60.8583, 28.3887, 61.2583),
      _city('Hameenlinna','FI', 60.9960, 24.4643, 24.2643, 60.7960, 24.6643, 61.1960),
      _city('Vaasa','FI', 63.0951, 21.6165, 21.4165, 62.8951, 21.8165, 63.2951),
      _city('Rovaniemi','FI', 66.5039, 25.7294, 25.5294, 66.3039, 25.9294, 66.7039),
      _city('Seinajoki','FI', 62.7903, 22.8405, 22.6405, 62.5903, 23.0405, 62.9903),
      _city('Mikkeli','FI', 61.6886, 27.2736, 27.0736, 61.4886, 27.4736, 61.8886),
      _city('Kotka','FI', 60.4660, 26.9450, 26.7450, 60.2660, 27.1450, 60.6660),
    ],

    'EE': [
      _city('Tallinn','EE', 59.4370, 24.7536, 24.5536, 59.2370, 24.9536, 59.6370),
      _city('Tartu','EE', 58.3776, 26.7290, 26.5290, 58.1776, 26.9290, 58.5776),
      _city('Narva','EE', 59.3793, 28.2000, 28.0000, 59.1793, 28.4000, 59.5793),
    ],

    // ---------------- LATVIA (LV) ----------------
    'LV': [
      _city('Riga','LV', 56.9496, 24.1052, 23.9052, 56.7496, 24.3052, 57.1496),
      _city('Daugavpils','LV', 55.8740, 26.5362, 26.3362, 55.6740, 26.7362, 56.0740),
      _city('Liepaja','LV', 56.5047, 21.0108, 20.8108, 56.3047, 21.2108, 56.7047),
      _city('Jelgava','LV', 56.6511, 23.7214, 23.5214, 56.4511, 23.9214, 56.8511),
      _city('Jurmala','LV', 56.9710, 23.7497, 23.5497, 56.7710, 23.9497, 57.1710),
    ],

    // ---------------- LITHUANIA (LT) ----------------
    'LT': [
      _city('Vilnius','LT', 54.6872, 25.2797, 25.0797, 54.4872, 25.4797, 54.8872),
      _city('Kaunas','LT', 54.8985, 23.9036, 23.7036, 54.6985, 24.1036, 55.0985),
      _city('Klaipeda','LT', 55.7033, 21.1443, 20.9443, 55.5033, 21.3443, 55.9033),
      _city('Siauliai','LT', 55.9333, 23.3167, 23.1167, 55.7333, 23.5167, 56.1333),
      _city('Panevezys','LT', 55.7333, 24.3500, 24.1500, 55.5333, 24.5500, 55.9333),
      _city('Alytus','LT', 54.3964, 24.0414, 23.8414, 54.1964, 24.2414, 54.5964),
    ],

    'DE': [
      _city('Berlin',   'DE', 52.5200, 13.4050, 13.2050, 52.3200, 13.6050, 52.7200),
      _city('Hamburg',  'DE', 53.5511,  9.9937,  9.7937, 53.3511, 10.1937, 53.7511),
      _city('Munich',   'DE', 48.1372, 11.5755, 11.3755, 47.9372, 11.7755, 48.3372),
      _city('Frankfurt','DE', 50.1109,  8.6821,  8.4821, 49.9109,  8.8821, 50.3109),
      _city('Cologne',  'DE', 50.9375,  6.9603,  6.7603, 50.7375,  7.1603, 51.1375),
      _city('Stuttgart','DE', 48.7758,  9.1829,  8.9829, 48.5758,  9.3829, 48.9758),
    ],
    'GB': [
      _city('London',   'GB', 51.5283, -0.0833, -0.2833, 51.3283, 0.1167, 51.7283),
      _city('Manchester','GB',53.4808, -2.2426, -2.4426, 53.2808, -2.0426, 53.6808),
      _city('Edinburgh','GB', 55.9533, -3.1883, -3.3883, 55.7533, -2.9883, 56.1533),
      _city('Glasgow',  'GB', 55.8658, -4.2515, -4.4515, 55.6658, -4.0515, 56.0658),
      _city('Liverpool','GB', 53.4084, -2.9916, -3.1916, 53.2084, -2.7916, 53.6084),
    ],
    'FR': [
      _city('Paris',    'FR', 48.8534,  2.3488,  2.1488, 48.6534,  2.5488, 49.0534),
      _city('Marseille','FR', 43.2965,  5.3698,  5.1698, 43.0965,  5.5698, 43.4965),
      _city('Lyon',     'FR', 45.7640,  4.8357,  4.6357, 45.5640,  5.0357, 45.9640),
      _city('Bordeaux', 'FR', 44.8378, -0.5792, -0.7792, 44.6378, -0.3792, 45.0378),
    ],
    'ES': [
      _city('Madrid',   'ES', 40.4168, -3.7038, -3.9038, 40.2168, -3.5038, 40.6168),
      _city('Barcelona','ES', 41.3851,  2.1734,  1.9734, 41.1851,  2.3734, 41.5851),
      _city('Valencia', 'ES', 39.4699, -0.3763, -0.5763, 39.2699, -0.1763, 39.6699),
      _city('Seville',  'ES', 37.3891, -5.9845, -6.1845, 37.1891, -5.7845, 37.5891),
    ],
    'IT': [
      _city('Rome',     'IT', 41.9028, 12.4964, 12.2964, 41.7028, 12.6964, 42.1028),
      _city('Milan',    'IT', 45.4642,  9.1895,  8.9895, 45.2642,  9.3895, 45.6642),
      _city('Naples',   'IT', 40.8526, 14.2681, 14.0681, 40.6526, 14.4681, 41.0526),
      _city('Turin',    'IT', 45.0703,  7.6869,  7.4869, 44.8703,  7.8869, 45.2703),
    ],
    'NL': [
      _city('Amsterdam','NL', 52.3676,  4.9041,  4.7041, 52.1676,  5.1041, 52.5676),
      _city('Rotterdam','NL', 51.9244,  4.4777,  4.2777, 51.7244,  4.6777, 52.1244),
      _city('The Hague','NL', 52.0705,  4.3007,  4.1007, 51.8705,  4.5007, 52.2705),
      _city('Utrecht',  'NL', 52.0907,  5.1214,  4.9214, 51.8907,  5.3214, 52.2907),
    ],
    'NO': [
      _city('Oslo',     'NO', 59.9139, 10.7522, 10.5522, 59.7139, 10.9522, 60.1139),
      _city('Bergen',   'NO', 60.3913,  5.3221,  5.1221, 60.1913,  5.5221, 60.5913),
      _city('Trondheim','NO', 63.4305, 10.3951, 10.1951, 63.2305, 10.5951, 63.6305),
    ],

    'IE': [
      _city('Dublin',   'IE', 53.3498, -6.2603, -6.4603, 53.1498, -6.0603, 53.5498),
    ],
    'AT': [
      _city('Vienna',   'AT', 48.2082, 16.3738, 16.1738, 48.0082, 16.5738, 48.4082),
      _city('Graz',     'AT', 47.0707, 15.4395, 15.2395, 46.8707, 15.6395, 47.2707),
      _city('Linz',     'AT', 48.3069, 14.2858, 14.0858, 48.1069, 14.4858, 48.5069),
    ],
    'PL': [
      _city('Warsaw',   'PL', 52.2297, 21.0122, 20.8122, 52.0297, 21.2122, 52.4297),
      _city('Krakow',   'PL', 50.0647, 19.9450, 19.7450, 49.8647, 20.1450, 50.2647),
      _city('Wroclaw',  'PL', 51.1079, 17.0385, 16.8385, 50.9079, 17.2385, 51.3079),
    ],
    'RO': [
      _city('Bucharest','RO', 44.4268, 26.1025, 25.9025, 44.2268, 26.3025, 44.6268),
      _city('Cluj-Napoca','RO',46.7712,23.6236, 23.4236, 46.5712, 23.8236, 46.9712),
      _city('Timisoara','RO', 45.7489, 21.2087, 21.0087, 45.5489, 21.4087, 45.9489),
    ],
    'BG': [
      _city('Sofia',    'BG', 42.6977, 23.3219, 23.1219, 42.4977, 23.5219, 42.8977),
      _city('Plovdiv',  'BG', 42.1354, 24.7453, 24.5453, 41.9354, 24.9453, 42.3354),
      _city('Varna',    'BG', 43.2141, 27.9147, 27.7147, 43.0141, 28.1147, 43.4141),
    ],
    'GR': [
      _city('Athens',   'GR', 37.9838, 23.7275, 23.5275, 37.7838, 23.9275, 38.1838),
      _city('Thessaloniki','GR',40.6401,22.9444,22.7444,40.4401,23.1444,40.8401),
    ],
    'CH': [
      _city('Zurich',   'CH', 47.3769,  8.5417,  8.3417, 47.1769,  8.7417, 47.5769),
      _city('Geneva',   'CH', 46.2044,  6.1432,  5.9432, 46.0044,  6.3432, 46.4044),
      _city('Basel',    'CH', 47.5596,  7.5886,  7.3886, 47.3596,  7.7886, 47.7596),
    ],
    // Add more countries/cities as needed
  };

  static CityInfo _city(
      String name, String cc, double cLat, double cLon,
      double minLon, double minLat, double maxLon, double maxLat,
      ) {
    return CityInfo(
      name: name,
      countryCode: cc,
      center: LatLng(cLat, cLon),
      bbox: BoundingBox.fromLonLat(minLon: minLon, minLat: minLat, maxLon: maxLon, maxLat: maxLat),
    );
  }
}
