// lib/features/venues/widgets/mood_images_section.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/core/storage/storage_url.dart';
import 'package:nightowlcode/data/providers/venues/venue_media_providers.dart';
import 'package:nightowlcode/data/repositories/users/feedback_repository.dart';
import 'package:nightowlcode/data/repositories/users/role_repository.dart';

import 'package:nightowlcode/shared/constants/values.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/icons.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/utility/custom_network_image.dart';
import '../../../shared/reusable/ui/owl_snack.dart';

class MoodImagesSection extends ConsumerWidget {
  const MoodImagesSection({super.key, required this.venueId});
  final String venueId;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    // 🔐 Only admins / testers / reviewers can add mood images
    final roles = ref.watch(userRolesProvider);
    final canAdd = roles.isAdmin || roles.isTester || roles.isReviewer;

    return ref.watch(venueMediaBundleProvider(venueId)).when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (b) {
        final mood = b.moodImageUrls.map(StorageUrl.normalize).toList();

        // If no images AND user can't add → hide completely
        if (mood.isEmpty && !canAdd) return const SizedBox.shrink();

        return _HStrip(
          urls: mood,
          venueId: venueId,
          canAddMoodImage: canAdd,
          height: PlatformConfig.height(c) * 0.2,
          itemExtent: PlatformConfig.width(c) * 0.3,
          radius: borderRadiusDefault,
          ref: ref,
        );
      },
    );
  }
}

class _HStrip extends StatelessWidget {
  const _HStrip({
    required this.urls,
    required this.venueId,
    required this.canAddMoodImage,
    required this.height,
    required this.itemExtent,
    required this.ref,
    this.radius = 8,
    this.spacing = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 2),
    this.fit = BoxFit.cover,
  });

  final List<String> urls;
  final String venueId;
  final bool canAddMoodImage;
  final double height, itemExtent, radius, spacing;
  final EdgeInsets padding;
  final BoxFit fit;
  final WidgetRef ref;

  void _open(BuildContext c, int initial) {
    Navigator.of(c).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withOpacity(.95),
      pageBuilder: (_, __, ___) => _Gallery(urls: urls, initial: initial),
    ));
  }

  @override
  Widget build(BuildContext c) {
    final hasImages = urls.isNotEmpty;
    final addTileCount = canAddMoodImage ? 1 : 0;
    final itemCount = urls.length + addTileCount;

    // No images and no permission → nothing
    if (!hasImages && !canAddMoodImage) {
      return const SizedBox.shrink();
    }

    // ⭐ Special case: ONLY "Add image" tile → center it
    if (!hasImages && canAddMoodImage) {
      return SizedBox(
        height: height,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: SizedBox(
              width: itemExtent,
              height: height,
              child: InkWell(
                onTap: () => _handleAddMoodImage(
                  c,
                  ref: ref,
                  venueId: venueId,
                ),
                splashColor: owlPurple.withOpacity(0.15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 🔹 Grey border + black background
                    Container(
                      decoration: BoxDecoration(
                        color: black,
                        border: Border.all(color: grey, width: 0.6),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_a_photo_outlined,
                          color: white,
                          size: iconSizeDefault,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add image',
                          style: Styles.smallText.copyWith(
                            fontSize: 11,
                            color: greyLighter,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Normal case: one or more mood images (+ optional "Add image" as last tile)
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(width: spacing),
        itemBuilder: (_, i) {
          final isAddTile = canAddMoodImage && i == itemCount - 1;

          // ▶️ Right-most "Add image" tile — matches normal tile dimensions + placement
          if (isAddTile) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: SizedBox(
                width: itemExtent,
                height: height,
                child: InkWell(
                  onTap: () => _handleAddMoodImage(
                    c,
                    ref: ref,
                    venueId: venueId,
                  ),
                  splashColor: owlPurple.withOpacity(0.15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 🔹 Grey border + black background
                      Container(
                        decoration: BoxDecoration(
                          color: black,
                          border: Border.all(color: grey, width: 0.6),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo_outlined,
                            color: white,
                            size: iconSizeDefault,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add image',
                            style: Styles.smallText.copyWith(
                              fontSize: 11,
                              color: greyLighter,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // ▶️ Normal mood image tile
          final url = urls[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: InkWell(
              onTap: () => _open(c, i),
              child: Hero(
                tag: url,
                child: SizedBox(
                  width: itemExtent,
                  height: height,
                  child: CustomNetworkImage(url, fit: fit),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
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
                    child: CustomNetworkImage(
                      widget.urls[i],
                      fit: BoxFit.contain,
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Helpers: pick image + upload
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _handleAddMoodImage(
    BuildContext context, {
      required WidgetRef ref,
      required String venueId,
    }) async {
  final rootCtx = Navigator.of(context, rootNavigator: true).context;

  final src = await _chooseMoodImageSource(rootCtx);
  if (src == null) return;

  final picked = await ImagePicker().pickImage(
    source: src,
    requestFullMetadata: true,
    maxWidth: 2000,
    maxHeight: 2000,
  );
  if (picked == null) return;

  final file = File(picked.path);

  try {
    await FeedbackRepository.uploadMoodImage(
      venueId: venueId,
      file: file,
    );

    // Make sure the updated mood images are shown
    ref.invalidate(venueMediaBundleProvider(venueId));

    OwlSnack.show(
      rootCtx,
      title: 'Mood image added',
      message: 'Hoot hoot! The vibes just got better 🦉',
      variant: OwlSnackVariant.success,
    );
  } catch (e) {
    OwlSnack.show(
      rootCtx,
      title: 'Could not add image',
      message: '$e',
      variant: OwlSnackVariant.error,
    );
  }
}

Future<ImageSource?> _chooseMoodImageSource(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    useRootNavigator: true,
    backgroundColor: black,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              cameraIcon,
              size: iconSizeDefault,
              color: owlPurple,
            ),
            title: Text('Take photo', style: Styles.basicText),
            onTap: () => Navigator.of(ctx, rootNavigator: true)
                .pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(
              photoLibraryIcon,
              size: iconSizeDefault,
              color: owlPurple,
            ),
            title: Text('Choose from gallery', style: Styles.basicText),
            onTap: () => Navigator.of(ctx, rootNavigator: true)
                .pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}
