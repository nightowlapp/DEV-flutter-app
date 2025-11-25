// lib/features/explore/utility/cover_image.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/utility/city_asset.dart';
import '../../../shared/utility/custom_network_image.dart';

const _defaultAsset = 'assets/nightowl/cities/default.png';

class CoverImage extends StatelessWidget {
  final String? imageUrl;
  final double? height;
  final double heightFactor;
  final bool hideIfEmpty;
  final Gradient? overlayGradient;
  final Widget? foreground;
  final BoxFit fit;
  final Alignment alignment;
  final bool useDeviceCacheWidth;
  final int? memCacheWidth;
  final int maxAutoCacheWidth;
  final bool fallBackEnabled;
  final String? fallbackAsset; // e.g. city asset

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
    this.fallbackAsset,
  });

  factory CoverImage.fromMedia({
    Key? key,
    required dynamic media,
    required String? city,
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

    final cityAsset = assetForCity(city);
    final shouldHideIfEmpty = hasCover ? hideIfEmpty : false;

    return CoverImage(
      key: key,
      imageUrl: hasCover ? media.coverUrl as String : null,
      fallbackAsset: cityAsset,
      height: height,
      heightFactor: heightFactor,
      hideIfEmpty: shouldHideIfEmpty,
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
debugPrint('$url !!!!');
    if (hideIfEmpty && url.isEmpty) return const SizedBox.shrink();

    final h = height ?? MediaQuery.of(context).size.height * heightFactor;
    final cacheWidth = _effectiveMemCacheWidth(context);
    final cityAsset = (fallbackAsset ?? '').trim();

    return SizedBox(
      height: h,
      child: OverflowBox(
        alignment: alignment,
        minWidth: 0,
        maxWidth: double.infinity,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url.isNotEmpty)
                // Network first; fall back to default asset if it fails
                CustomNetworkImage(
                  url,
                  fit: fit,
                  memCacheWidth: cacheWidth,
                  fallBackEnabled: fallBackEnabled,
                  fallbackAsset: _defaultAsset,
                )
              else if (fallBackEnabled)
                // Try city asset, then default.png, then nothing
                Image.asset(
                  cityAsset.isNotEmpty ? cityAsset : _defaultAsset,
                  fit: fit,
                  errorBuilder: (_, __, ___) => Image.asset(
                    _defaultAsset,
                    fit: fit,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                )
              else
                const SizedBox.shrink(),
              if (overlayGradient != null)
                DecoratedBox(
                    decoration: BoxDecoration(gradient: overlayGradient!)),
              if (foreground != null) foreground!,
            ],
          ),
        ),
      ),
    );
  }
}
