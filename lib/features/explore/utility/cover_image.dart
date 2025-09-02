import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../shared/utility/custom_network_image.dart';

class CoverImage extends StatelessWidget {
  /// Network image url (http/https, gs://, or storage path). If empty/null:
  /// - returns SizedBox.shrink() when [hideIfEmpty] == true
  /// - shows transparent box otherwise
  final String? imageUrl;

  /// Exact height. If null, uses [heightFactor] of viewport height.
  final double? height;

  /// Fraction of screen height to use when [height] is null. Default 0.25.
  final double heightFactor;

  /// Collapse when url empty.
  final bool hideIfEmpty;

  /// Optional top overlay gradient.
  final Gradient? overlayGradient;

  /// Optional foreground widget placed above the image.
  final Widget? foreground;

  /// Image fit.
  final BoxFit fit;

  /// Alignment for the internal OverflowBox.
  final Alignment alignment;

  /// Whether to compute an appropriate memCacheWidth from current device width.
  /// Keeps cached image sharp while avoiding oversized cache entries.
  final bool useDeviceCacheWidth;

  /// Optional hard override for memCacheWidth (in pixels).
  /// Ignored if [useDeviceCacheWidth] is true.
  final int? memCacheWidth;

  /// Upper bound when auto-computing memCacheWidth (safety).
  final int maxAutoCacheWidth;

  /// Show fallback asset while loading/error.
  final bool fallBackEnabled;

  const CoverImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.heightFactor = 0.25,
    this.hideIfEmpty = true,
    this.overlayGradient,
    this.foreground,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.useDeviceCacheWidth = true,
    this.memCacheWidth,
    this.maxAutoCacheWidth = 2048,
    this.fallBackEnabled = true,
  });

  /// Convenience ctor for your media object (e.g., VenueMediaHealth).
  factory CoverImage.fromMedia({
    Key? key,
    required dynamic media, // e.g. VenueMediaHealth
    double? height,
    double heightFactor = 0.25,
    bool hideIfEmpty = true,
    Gradient? overlayGradient,
    Widget? foreground,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    bool useDeviceCacheWidth = true,
    int? memCacheWidth,
    int maxAutoCacheWidth = 2048,
    bool fallBackEnabled = true,
  }) {
    final hasCover = media != null &&
        (media.coverExists == true) &&
        (media.coverUrl is String) &&
        (media.coverUrl?.isNotEmpty ?? false);

    return CoverImage(
      key: key,
      imageUrl: hasCover ? media.coverUrl as String : null,
      height: height,
      heightFactor: heightFactor,
      hideIfEmpty: hideIfEmpty,
      overlayGradient: overlayGradient,
      foreground: foreground,
      fit: fit,
      alignment: alignment,
      useDeviceCacheWidth: useDeviceCacheWidth,
      memCacheWidth: memCacheWidth,
      maxAutoCacheWidth: maxAutoCacheWidth,
      fallBackEnabled: fallBackEnabled,
    );
  }

  int? _effectiveMemCacheWidth(BuildContext context) {
    if (!useDeviceCacheWidth) return memCacheWidth;
    final w = MediaQuery.of(context).size.width;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final px = (w * dpr).round();
    return math.min(px, maxAutoCacheWidth);
  }

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl ?? '').trim();
    if (hideIfEmpty && url.isEmpty) return const SizedBox.shrink();

    final h = height ?? MediaQuery.of(context).size.height * heightFactor;
    final cacheWidth = _effectiveMemCacheWidth(context);

    return SizedBox(
      height: h,
      child: OverflowBox(
        alignment: alignment,
        minWidth: 0,
        maxWidth: double.infinity,
        child: SizedBox(
          width: MediaQuery.of(context).size.width, // full width
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url.isNotEmpty)
                CustomNetworkImage(
                  url,
                  fit: fit,
                  memCacheWidth: cacheWidth,
                  fallBackEnabled: fallBackEnabled,
                  // cacheKey defaults to url inside CustomNetworkImage
                )
              else
                const ColoredBox(color: Colors.transparent),
              if (overlayGradient != null)
                DecoratedBox(decoration: BoxDecoration(gradient: overlayGradient!)),
              if (foreground != null) foreground!,
            ],
          ),
        ),
      ),
    );
  }
}
