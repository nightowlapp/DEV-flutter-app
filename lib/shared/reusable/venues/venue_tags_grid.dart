import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import '../../../data/providers/other_providers.dart';
import '../../../data/services/tags/tag_helpers.dart';
import '../../../models/venues/tag.dart';

/// Lightweight, no-dependency tag pills (adjust styling to your design).
class VenueTagsGrid extends ConsumerWidget {
  const VenueTagsGrid({
    super.key,
    required this.tagIds,
    required this.viewportWidth,
    required this.viewportHeight,
    this.rows = 2,
    this.onAddTag,
  });

  /// Current tag ids shown in the grid.
  final List<String> tagIds;

  final double viewportWidth;
  final double viewportHeight;
  final int rows;

  /// Callback when the "Add tag" pill is tapped.
  final VoidCallback? onAddTag;

  static const int _maxTagCountForAddButton = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Local, instant, sorted by your tagTypeOrderProvider
    final tags = ref.watch(localSortedTagsByIdsProvider(tagIds));

    if (tags.isEmpty) {
      // At cold start this might be empty until SSO loads; show a tiny loader or nothing.
      return _boxed(const LoadingIndicator());
    }

    final tagWidth = viewportWidth * 0.4;
    final tagHeight = viewportHeight * 0.13;
    const vPad = 8.0, hPad = 6.0;
    const mainAxisSpacing = 10.0,
        crossAxisSpacing = 5.0,
        childAspectRatio = 5.0;
    const chipHeight = 28.0;

    final bool showAddTagButton = tags.length < _maxTagCountForAddButton;
    final int visualItemCount = tags.length + (showAddTagButton ? 1 : 0);

    // Ensure the "visual order" is:
    // first: top-left, second: top-right, third: bottom-left, fourth: bottom-right, ...
    // The "Add tag" chip is always the last in this visual order.
    final gridToVisualIndex = _computeGridToVisualIndex(
      itemCount: visualItemCount,
      rows: rows,
    );

    return SizedBox(
      height: tagHeight,
      child: _boxed(
        GridView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
          itemCount: visualItemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: rows,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
            mainAxisExtent: tagWidth,
          ),
          itemBuilder: (context, gridIndex) {
            final visualIndex = gridToVisualIndex[gridIndex];
            final bool isAddTagItem =
                showAddTagButton && visualIndex == visualItemCount - 1;

            return SizedBox(
              height: chipHeight,
              child: isAddTagItem
                  ? _addTagChip(
                width: tagWidth,
                height: tagHeight,
                onTap: onAddTag,
              )
                  : _tagChip(
                tags[visualIndex],
                tagWidth,
                tagHeight,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Maps the internal GridView item index (column-major) to the "visual"
  /// order index (row-major: top-left, top-right, bottom-left, bottom-right, ...).
  List<int> _computeGridToVisualIndex({
    required int itemCount,
    required int rows,
  }) {
    if (itemCount <= 1 || rows <= 1) {
      // Trivial mapping – nothing to reorder.
      return List<int>.generate(itemCount, (i) => i);
    }

    final indices = List<int>.generate(itemCount, (i) => i);

    indices.sort((a, b) {
      final rowA = a % rows;
      final colA = a ~/ rows;
      final rowB = b % rows;
      final colB = b ~/ rows;

      final rowCompare = rowA.compareTo(rowB);
      if (rowCompare != 0) return rowCompare;
      return colA.compareTo(colB);
    });

    final gridToVisual = List<int>.filled(itemCount, 0);
    for (var visual = 0; visual < itemCount; visual++) {
      final gridIndex = indices[visual];
      gridToVisual[gridIndex] = visual;
    }
    return gridToVisual;
  }

  Widget _boxed(Widget child) => Container(
    decoration: BoxDecoration(
      color: black,
      border: Border.all(color: white, width: 1.5),
      borderRadius: BorderRadius.circular(borderRadiusSmall),
    ),
    child: child,
  );
}

Widget _tagChip(Tag tag, double width, double height) {
  final color = owlPurple;

  final emoji = tag.emoji.isNotEmpty ? tag.emoji : '';
  final label = tag.name.isNotEmpty ? tag.name : '';

  return Container(
    decoration: BoxDecoration(
      color: black,
      borderRadius: BorderRadius.circular(borderRadiusSmallest),
      border: Border.all(color: color, width: 1),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.40),
          blurRadius: 8,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: color.withOpacity(0.20),
          blurRadius: 2,
          spreadRadius: 0.5,
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Row(
      children: [
        Container(
          width: width * 0.25,
          height: height * 0.3,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(borderRadiusSmallest),
            border: Border.all(color: color, width: 0.7),
          ),
          alignment: Alignment.center,
          child: Text(
            emoji,
            style: const TextStyle(fontSize: fontSizeMediumPlus),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            // TODO Marquee if too long.
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

Widget _addTagChip({
  required double width,
  required double height,
  VoidCallback? onTap,
}) {
  // Use your green accent color here
  final borderColor = grey;

  final chip = Container(
    decoration: BoxDecoration(
      color: black,
      borderRadius: BorderRadius.circular(borderRadiusSmallest),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: borderColor.withOpacity(0.40),
          blurRadius: 8,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: borderColor.withOpacity(0.20),
          blurRadius: 2,
          spreadRadius: 0.5,
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Row(
      children: [
        Container(
          width: width * 0.25,
          height: height * 0.3,
          decoration: BoxDecoration(
            color: borderColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(borderRadiusSmallest),
            border: Border.all(color: borderColor, width: 0.7),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.add,
            size: fontSizeMediumPlus,
            color: white, // white "+" as requested
          ),
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Text(
            'Add tag',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: white,
            ),
          ),
        ),
      ],
    ),
  );

  if (onTap == null) return chip;

  return GestureDetector( //TODO add tag hooked up - look through all tags and add. Maybe only for reviewers/testers?
    onTap: onTap,
    child: chip,
  );
}
