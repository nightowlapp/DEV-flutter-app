// lib/shared/utility/city_asset.dart
library city_asset;

/// Returns the asset path for a city's fallback image.
/// "Copenhagen" -> "assets/nightowl/copenhagen.png"
///
/// If your filenames exactly match `venue.city` (including spaces/case),
/// call with `slug: false`.
String assetForCity(String? city, {bool slug = true}) {
  final raw = (city ?? '').trim();
  if (raw.isEmpty) return 'assets/nightowl/cities/default.png';

  if (!slug) return 'assets/nightowl/cities/$raw.png';

  final s = raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return 'assets/nightowl/cities/${s.isEmpty ? 'default' : s}.png';
}

