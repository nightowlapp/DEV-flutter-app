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
  });
//TODO Add tag button - espicailly if few tags. Also if many?
  final List<String> tagIds;
  final double viewportWidth;
  final double viewportHeight;
  final int rows;

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

    return SizedBox(
      height: tagHeight,
      child: _boxed(
        GridView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
          itemCount: tags.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: rows,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
            mainAxisExtent: tagWidth,
          ),
          itemBuilder: (context, i) => SizedBox(
            height: chipHeight,
            child: _tagChip(tags[i], tagWidth, tagHeight),
          ),
        ),
      ),
    );
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

Widget _tagChip(Tag tag, width, height) {
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
            color: color.withOpacity(0.40), blurRadius: 8, spreadRadius: 1),
        BoxShadow(
            color: color.withOpacity(0.20), blurRadius: 2, spreadRadius: 0.5),
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
          child:
              Text(emoji, style: const TextStyle(fontSize: fontSizeMediumPlus)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            //TODO Marq if too long.
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
