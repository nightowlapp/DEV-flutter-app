// lib/shared/utility/city_asset.dart
library city_asset;

const _kDefault = 'assets/nightowl/cities/default.png';

String assetForCity(String? city, {bool slug = true}) {
  final raw = (city ?? '').trim();
  if (raw.isEmpty) return _kDefault;

  if (!slug) return 'assets/nightowl/cities/$raw.png';

  final s = raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return 'assets/nightowl/cities/${s.isEmpty ? 'default' : s}.png';
}
