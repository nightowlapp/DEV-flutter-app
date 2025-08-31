// lib/shared/widgets/custom_network_image.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Drop-in network image with built-in safety:
/// - If URL is empty/invalid → shows fallback asset
/// - While loading → shows fallback asset
/// - On error → shows fallback asset
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
        this.fallbackAsset = 'assets/nightowl/logo.png',
        this.fallbackSize = const Size(50, 50),
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

  /// Default fallback logo asset (make sure it’s in pubspec.yaml).
  final String fallbackAsset;

  /// Size of the centered fallback logo.
  final Size fallbackSize;

  bool _isHttp(String s) => s.startsWith('http://') || s.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    Widget fallback() => _wrap(
      Center(
        child: SizedBox(
          width:50,
          height: 50,
          child: Image.asset(fallbackAsset, fit: BoxFit.contain),
        ),
      ),
    );

    final u = url.trim();
    if (u.isEmpty || !_isHttp(u)) {
      // Invalid URL → fallback
      return fallback();
    }

    final img = CachedNetworkImage(
      imageUrl: u,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      memCacheWidth: memCacheWidth,
      httpHeaders: httpHeaders,
      cacheKey: cacheKey ?? u,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      // Loading → fallback
      placeholder: (_, __) => fallback(),
      // Error → fallback (and log in debug)
      errorWidget: (_, __, err) {
        assert(() {
          if (kDebugMode) debugPrint('CustomNetworkImage error for $u -> $err');
          return true;
        }());
        return fallback();
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
