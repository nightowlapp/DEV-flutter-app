// lib/features/venues/widgets/offer_today_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/data/providers/venues/venue_media_providers.dart';
import 'package:nightowlcode/core/storage/storage_url.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import '../../../shared/utility/custom_network_image.dart';

class OfferTodaySection extends ConsumerWidget {
  const OfferTodaySection({super.key, required this.venueId});
  final String venueId;

  @override
  Widget build(BuildContext c, WidgetRef ref) =>
      ref.watch(venueMediaBundleProvider(venueId)).when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (b) {
              // pick today's daily offer, else default offer
              final todayIdx = DateTime.now().weekday - 1; // Mon=0..Sun=6
              String? url;
              for (final e in b.dailyOfferUrls.entries) {
                if (e.key.index == todayIdx) {
                  url = StorageUrl.normalize(e.value);
                  break;
                }
              }
              url ??= (b.defaultOfferUrl?.isNotEmpty == true)
                  ? StorageUrl.normalize(b.defaultOfferUrl!)
                  : null;
              if (url == null) return const SizedBox.shrink();

              final w = PlatformConfig.width(c) * 0.72;
              final h = PlatformConfig.height(c) * 0.24;

              return Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadiusDefault),
                  child: InkWell(
                    onTap: () => _open(c, url!),
                    child: Hero(
                      tag: url!,
                      child: SizedBox(
                        width: w,
                        height: h,
                        child: CustomNetworkImage(url, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              );
            },
          );

  void _open(BuildContext c, String url) {
    Navigator.of(c).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withOpacity(.95),
      pageBuilder: (_, __, ___) => _OfferViewer(url: url),
    ));
  }
}

class _OfferViewer extends StatelessWidget {
  const _OfferViewer({required this.url});
  final String url;

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: url,
                child: InteractiveViewer(
                  maxScale: 4,
                  child: CustomNetworkImage(url, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: white),
                onPressed: () => Navigator.of(c).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
