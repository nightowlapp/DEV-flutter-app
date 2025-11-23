// lib/features/explore/filters/filters_popup.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/styles.dart';

import '../../../shared/reusable/ui/owl_scrollbar.dart';
import 'filter_controller.dart';
import 'popup_widgets/distance_filter_section.dart';
import 'popup_widgets/rating_filter_section.dart';
import 'popup_widgets/age_filter_section.dart';
import 'popup_widgets/venue_type_filter_section.dart';

Future<void> showFiltersPopup(BuildContext context, WidgetRef ref) async {
  await showGeneralDialog(
    context: context,
    barrierLabel: 'Filters',
    barrierDismissible: true,
    barrierColor: transparent,
    transitionBuilder: (ctx, anim, _, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween(begin: .98, end: 1.0).animate(curve),
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, _, __) {
      final dy = PlatformConfig.height(context) * 0.035;
      return Center(
        child: Transform.translate(
          offset: Offset(0, dy),
          child: FractionallySizedBox(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: PlatformConfig.width(context) * 0.9,
                maxHeight: PlatformConfig.height(context) * 0.7,
              ),
              child: const _FiltersCard(),
            ),
          ),
        ),
      );
    },
  );
}

class _FiltersCard extends ConsumerWidget {
  const _FiltersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filtersProvider);
    final ctrl = ref.read(filtersProvider.notifier);

    final double outerRadius = borderRadiusDefault * 1.6;

    return Material(
      color: black,
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(outerRadius),
        side: const BorderSide(color: grey, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(outerRadius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(
                horizontalSpacerDefault,
                horizontalSpacerDefault,
                horizontalSpacerDefault,
                horizontalSpacerSmall,
              ),
              child: Row(
                children: [
                  Text('Filters', style: Styles.popupHeader),
                  const Spacer(),
                  Text('Open now', style: Styles.smallText),
                  const SizedBox(width: 6),
                  Switch.adaptive(
                    value: filters.openNowOnly,
                    onChanged: ctrl.setOpenNow,
                    activeColor: owlPurple,
                    trackOutlineColor:
                    WidgetStatePropertyAll(grey.withOpacity(.5)),
                    inactiveThumbColor: grey,
                    inactiveTrackColor: grey.withOpacity(.35),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Pro Tip: ',
                  style: Styles.smallText.copyWith(color: owlPurple),
                ),
                Text(
                  'You can change your default filters in settings',
                  style: Styles.smallText,
                ),
              ],
            ),
            const Divider(color: grey),

            // BODY
            const Expanded(
              child: OwlScrollbar(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    vertical: verticalSpacerDefault,
                  ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DistanceFilterSection(),
                        RatingFilterSection(),
                        AgeRestrictionFilterSection(),
                        VenueTypeFilterSection(),
                        //TODO Other filters like entry price, dresscode, tags, most people right now / empty
                      ],
                    ),
                  ),
                ),
              ),
            // FOOTER
            Padding(
              padding: const EdgeInsets.fromLTRB(
                horizontalSpacerDefault,
                horizontalSpacerSmall,
                horizontalSpacerDefault,
                horizontalSpacerSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: ctrl.reset,
                    child: Text(
                      'Reset Filters',
                      style: Styles.smallText.copyWith(color: red),
                    ),
                  ),
                  TextButton(
                    onPressed: ctrl.reset,
                    child: Text(
                      'Reset Filters',
                      style: Styles.smallText.copyWith(color: red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
