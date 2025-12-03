import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/venues/venue_status_color_provider.dart';
import '../../../data/providers/visits/visits_provider.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/constants/values.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/reusable/ui/venue_logo.dart';
import '../../../shared/utility/utility.dart';

class VisitsSection extends ConsumerWidget {
  const VisitsSection({
    super.key,
    this.maxHeight, // ← nullable: if null, fills as much as parent allows
    this.title = 'My Visits',
    this.rightCaption = 'See All',
    this.seeAllEnabled = true,
    this.onRightTap,
    this.avatarRadius = iconSizeDefault,
    this.badgeColor = purpleAccent,
  });

  /// Optional hard cap. If `null`, the section will expand to parent's height.
  final double? maxHeight;
  final String title;
  final String rightCaption;
  final VoidCallback? onRightTap;
  final double avatarRadius;
  final Color badgeColor;
  final bool seeAllEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myVisitsWithVenuesProvider);

    // Total visits for left header
    final total = data.fold<int>(0, (sum, e) => sum + e.visits);

    // Row height: at least 44 for touch + pill content.
    final rowH = math.max(avatarRadius * 2, 44.0);
    final contentH =
    data.isEmpty ? rowH : (data.length * rowH) + ((data.length - 1) * 8.0);

    // Header height (title + spacing below)
    const headerH = 32.0 + verticalSpacerSmall;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBounded = constraints.hasBoundedHeight;
        final parentCap = hasBounded
            ? math.max(0.0, constraints.maxHeight - headerH)
            : double.infinity;

        // If maxHeight is null → fill as much as possible (use parentCap).
        // If maxHeight is set → clamp to min(parentCap, maxHeight).
        final targetCap =
        maxHeight == null ? parentCap : math.min(parentCap, maxHeight!);

        final listHeight = hasBounded ? targetCap : (maxHeight ?? contentH);

        // Enable scrolling only when needed
        final needsScroll = contentH > listHeight;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            SizedBox(
              height: 32,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('$total', style: Styles.basicText),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text(title, style: Styles.basicText),
                  ),
                  if (seeAllEnabled)
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: onRightTap,
                        child: Text(rightCaption, style: Styles.basicText),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: verticalSpacerSmall),

            if (data.isEmpty)
              SizedBox(
                height: listHeight,
                child: Center(
                  child: Text(
                    'No visits',
                    style: Styles.basicText.copyWith(color: red),
                  ),
                ),
              )
            else
              SizedBox(
                height: listHeight,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  primary: false,
                  physics: needsScroll
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final v = data[i].venue;
                    final visits = data[i].visits;
                    final dim = avatarRadius * 2;

                    final borderColor = ref.watch(venueStatusColorProvider(v));

                    return SizedBox(
                      height: rowH,
                      child: Row(
                        children: [
                          VenueLogo(
                            venue: v,
                            size: dim,
                            showTypeIfNoLogo: true,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  v.displayName.isNotEmpty
                                      ? v.displayName
                                      : v.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Styles.boldText
                                      .copyWith(fontSize: fontSizeSmall),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Utility.formatString(v.city),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Styles.smallText.copyWith(
                                    color: blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: badgeColor, width: 1),
                            ),
                            child: Text(
                              '${visits}x',
                              style: Styles.basicText.copyWith(
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
