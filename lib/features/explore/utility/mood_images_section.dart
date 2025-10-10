// lib/features/venues/widgets/venue_media_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/data/providers/venues/venue_media_providers.dart';
import 'package:nightowlcode/core/storage/storage_url.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/utility/custom_network_image.dart';

class MoodImagesSection extends ConsumerWidget {
  const MoodImagesSection({super.key, required this.venueId});
  final String venueId;

  @override
  Widget build(BuildContext c, WidgetRef ref) =>
      ref.watch(venueMediaBundleProvider(venueId)).when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (b) {
              final mood = b.moodImageUrls.map(StorageUrl.normalize).toList();
              return mood.isEmpty
                  ? const SizedBox.shrink()
                  : _HStrip(
                      urls: mood,
                      height: PlatformConfig.height(c) * 0.2,
                      itemExtent: PlatformConfig.width(c) * 0.3,
                      radius: borderRadiusDefault,
                    );
            },
          );
}

class _HStrip extends StatelessWidget {
  const _HStrip({
    required this.urls,
    required this.height,
    required this.itemExtent,
    this.radius = 8,
    this.spacing = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 2),
    this.fit = BoxFit.cover,
  });

  final List<String> urls;
  final double height, itemExtent, radius, spacing;
  final EdgeInsets padding;
  final BoxFit fit;

  void _open(BuildContext c, int initial) {
    Navigator.of(c).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withOpacity(.95),
      pageBuilder: (_, __, ___) => _Gallery(urls: urls, initial: initial),
    ));
  }

  @override
  Widget build(BuildContext c) => urls.isEmpty
      ? const SizedBox.shrink()
      : SizedBox(
          height: height,
          child: ListView.separated(
            padding: padding,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: urls.length,
            separatorBuilder: (_, __) => SizedBox(width: spacing),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: InkWell(
                onTap: () => _open(c, i),
                child: Hero(
                  tag: urls[i],
                  child: SizedBox(
                    width: itemExtent,
                    height: height,
                    child: CustomNetworkImage(urls[i], fit: fit),
                  ),
                ),
              ),
            ),
          ),
        );
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.urls, required this.initial});
  final List<String> urls;
  final int initial;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  late final PageController _pc = PageController(initialPage: widget.initial);
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _idx = widget.initial;
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pc,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _idx = i),
              itemBuilder: (_, i) => Center(
                child: Hero(
                  tag: widget.urls[i],
                  child: InteractiveViewer(
                    maxScale: 4,
                    child:
                        CustomNetworkImage(widget.urls[i], fit: BoxFit.contain),
                  ),
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
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_idx + 1}/${widget.urls.length}',
                    style: const TextStyle(color: white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
