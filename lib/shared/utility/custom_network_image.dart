// lib/shared/widgets/custom_network_image.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nightowlcode/assets.dart';

import '../../core/storage/storage_url.dart';

/// Drop-in network image with built-in safety:
/// - Accepts Firebase Storage paths, gs://, or http(s) URLs
/// - Empty/invalid → fallback asset (FULL-BLEED)
/// - Loading → fallback asset (FULL-BLEED)
/// - Error → fallback asset (FULL-BLEED)
/// - Optional clipping via borderRadius
class CustomNetworkImage extends StatelessWidget {
  const CustomNetworkImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.memCacheWidth = 1024,
    this.width,
    this.height,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
    this.fadeInDuration = const Duration(milliseconds: 200),
    this.fadeOutDuration = const Duration(milliseconds: 120),
    this.alignment = Alignment.center,
    this.cacheKey,
    this.httpHeaders,
    this.fallbackAsset = ImagePaths.logoWhite,
    this.fallBackEnabled = true,
    this.normalizeStorage = true,
  });

  final String url;
  final BoxFit fit;
  final int? memCacheWidth;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Clip clipBehavior;

  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final Alignment alignment;

  final String? cacheKey;
  final Map<String, String>? httpHeaders;

  final String fallbackAsset;
  final bool fallBackEnabled;

  /// If true (default), `url` can be a Storage path or `gs://` and will be
  /// converted to a direct https download URL.
  final bool normalizeStorage;

  bool _isHttp(String s) => s.startsWith('http://') || s.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    Widget fullBleedFallback() => _wrap(
          fallBackEnabled
              ? Image.asset(
                  fallbackAsset,
                  width: width,
                  height: height,
                  fit: fit, // <-- FULL BLEED
                  alignment: alignment,
                )
              : const SizedBox.shrink(),
        );

    final raw = url.trim();
    final resolved = normalizeStorage ? StorageUrl.normalize(raw) : raw;

    if (resolved.isEmpty || !_isHttp(resolved)) {
      return fullBleedFallback();
    }

    final img = CachedNetworkImage(
      imageUrl: resolved,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      memCacheWidth: memCacheWidth,
      httpHeaders: httpHeaders,
      cacheKey: cacheKey ?? resolved,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      placeholder: (_, __) => fullBleedFallback(),
      errorWidget: (_, __, err) {
        assert(() {
          if (kDebugMode)
            debugPrint('CustomNetworkImage error for $resolved -> $err');
          return true;
        }());
        return fullBleedFallback();
      },
    );

    return _wrap(img);
  }

  Widget _wrap(Widget child) {
    if (borderRadius == null) return child;
    return ClipRRect(
      borderRadius: borderRadius!,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
