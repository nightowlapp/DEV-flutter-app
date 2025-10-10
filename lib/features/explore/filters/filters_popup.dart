import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

import '../../../shared/constants/styles.dart';
import 'filter_controller.dart';

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
      final dy =
          PlatformConfig.height(context) * 0.035; // 10% of platform height
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

    // More rounded outer radius + grey border on the entire card
    final double outerRadius = borderRadiusDefault * 1.6;

    return Material(
      color: black,
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(outerRadius),
        side: BorderSide(color: grey, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(outerRadius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header (title + Open Today switch)
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
                  const Text('Open Now', style: TextStyle(color: white)),
                  SizedBox(width: verticalSpacerSmall),
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
            Divider(color: grey),

            // Scrollable body
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 3,
                radius: Radius.circular(borderRadiusDefault),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    verticalSpacerDefault,
                    verticalSpacerDefault,
                    verticalSpacerDefault,
                    verticalSpacerDefault,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Distance (km)
                      _CardSection(
                        title: 'Distance',
                        trailing: Text(
                          () {
                            final v = filters.maxDistanceKm;
                            if (v == null || v == 0) return 'off';
                            if (v >= 60) return '60+ km';
                            return '${v.round()} km';
                          }(),
                          style: Styles.basicText
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Immediate saving on change -> provider already updates
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: owlPurple,
                                inactiveTrackColor: grey.withOpacity(.3),
                                thumbColor: owlPurple,
                                overlayColor: owlPurple.withOpacity(.15),
                              ),
                              child: Slider(
                                min: 0,
                                max: 60,
                                divisions: 60,
                                value: (filters.maxDistanceKm ?? 0),
                                onChanged: (v) =>
                                    ctrl.setMaxDistanceKm(v == 0 ? null : v),
                              ),
                            ),
                            const _EmojiScale(),
                          ],
                        ),
                      ),

                      SizedBox(height: verticalSpacerDefault),

                      // Ratings
                      _CardSection(
                        title: 'Ratings',
                        trailing: Text(
                          filters.minRating == null
                              ? 'any'
                              : '${filters.minRating!.toStringAsFixed(1)}+',
                          style: Styles.basicText
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              // Approximate the "fill from right" feel by inverting colors & direction
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: grey.withOpacity(.35),
                                    inactiveTrackColor: owlPurple,
                                    thumbColor: owlPurple,
                                    overlayColor: owlPurple.withOpacity(.15),
                                  ),
                                  child: Slider(
                                    min: 0,
                                    max: 5,
                                    divisions: 10,
                                    value: (filters.minRating ?? 0),
                                    onChanged: (v) =>
                                        ctrl.setMinRating(v == 0 ? null : v),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _RatingFace(minRating: filters.minRating),
                          ],
                        ),
                      ),

                      SizedBox(height: verticalSpacerDefault),

                      //TODO NEED CHANGE
                      // Types (chips)
                      _CardSection(
                        title: 'Location type',
                        trailing: Text(
                          filters.types.isEmpty
                              ? 'All'
                              : '${filters.types.length}',
                          style: Styles.basicText
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // "All" chip visually selected when none chosen
                            FilterChip(
                              //TODO remove all.
                              label: Text(''),
                              selected: filters.types.isEmpty,
                              onSelected: (_) {
                                // Clear by toggling all currently selected types off
                                if (filters.types.isNotEmpty) {
                                  for (final t in filters.types.toList()) {
                                    ctrl.toggleType(t);
                                  }
                                }
                              },
                              selectedColor: owlPurple,
                              backgroundColor: grey,
                              side: BorderSide(
                                color: filters.types.isEmpty ? owlPurple : grey,
                                width: 0.7,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            ...VenueType.values
                                .where((t) => t != VenueType.unknown)
                                .map((t) {
                              final sel = filters.types.contains(t);
                              return FilterChip(
                                label: Text(
                                  Utility.formatString(t.name),
                                  style: TextStyle(color: sel ? black : white),
                                ),
                                selected: sel,
                                onSelected: (_) => ctrl.toggleType(t),
                                selectedColor: owlPurple,
                                backgroundColor: grey.withOpacity(.25),
                                side: BorderSide(
                                    color: sel ? owlPurple : grey, width: 0.7),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer actions
            Padding(
              padding: const EdgeInsets.fromLTRB(
                horizontalSpacerDefault,
                horizontalSpacerSmall,
                horizontalSpacerDefault,
                horizontalSpacerSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: ctrl.reset,
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        color: red,
                        fontSize: fontSizeSmall,
                      ),
                    ),
                    // TODO border
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

class _CardSection extends StatelessWidget {
  const _CardSection({
    required this.title,
    this.trailing,
    required this.child,
  });

  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // No section borders; keep spacing + subtle divider for structure
    return Container(
      padding: const EdgeInsets.all(horizontalSpacerDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style:
                    const TextStyle(color: white, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: verticalSpacerDefault),
          const Divider(color: grey),
          const SizedBox(height: verticalSpacerDefault),
          child,
        ],
      ),
    );
  }
}

class _EmojiScale extends StatelessWidget {
  const _EmojiScale();

  @override
  Widget build(BuildContext context) {
    const stops = <String>['🚶', '🚲', '🚌', '🚄', '✈️'];
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: stops.map((s) {
          final isEmoji = RegExp(r'[^\d]').hasMatch(s);
          return SizedBox(
            width: 28,
            child: Center(
              child: Text(
                s,
                style: TextStyle(
                  fontSize: isEmoji ? 16 : 12,
                  color: white.withOpacity(.85),
                  fontWeight: isEmoji ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RatingFace extends StatelessWidget {
  const _RatingFace({required this.minRating});
  final double? minRating;

  @override
  Widget build(BuildContext context) {
    final r = minRating ?? 0;
    String face;
    if (r >= 4.5) {
      face = '😍';
    } else if (r >= 3.5) {
      face = '😊'; // slightly less ecstatic than '😍'
    } else if (r >= 2.0) {
      face = '🙂';
    } else if (r > 0) {
      face = '🙁';
    } else {
      face = '⭐';
    }
    return Text(
      face,
    );
  }
}

extension on Text {
  Text copyWith({String? data, TextStyle? style}) =>
      Text(data ?? this.data ?? '', style: style ?? this.style);
}
