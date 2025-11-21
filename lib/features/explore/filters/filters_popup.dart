// lib/features/explore/filters/filters_popup.dart
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
                  const Text('Open now', style: TextStyle(color: white)),
                  const SizedBox(width: verticalSpacerSmall),
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
            const Divider(color: grey),

            // BODY
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 3,
                radius: Radius.circular(borderRadiusDefault),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(verticalSpacerDefault),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Distance
                      _CardSection(
                        title: 'Distance',
                        trailing: Text(
                              () {
                            final v = filters.maxDistanceKm;
                            if (v == null || v == 0) return 'Off';
                            if (v >= 60) return '60+ km';
                            return '${v.round()} km';
                          }(),
                          style: Styles.basicText.copyWith(
                            fontWeight: FontWeight.w600,
                            color: owlPurple,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                value: (filters.maxDistanceKm ?? 15),
                                onChanged: (v) =>
                                    ctrl.setMaxDistanceKm(v == 0 ? null : v),
                              ),
                            ),
                            const _EmojiScale(),
                          ],
                        ),
                      ),

                      const SizedBox(height: verticalSpacerDefault),

                      // Rating
                      _CardSection(
                        title: 'Rating',
                        trailing: Text(
                          filters.minRating == null
                              ? 'Any'
                              : '${filters.minRating!.toStringAsFixed(1)}+',
                          style: Styles.basicText.copyWith(
                            fontWeight: FontWeight.w600,
                            color: owlPurple,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: grey.withOpacity(.35),
                                    inactiveTrackColor: owlPurple,
                                    thumbColor: owlPurple,
                                    overlayColor:
                                    owlPurple.withOpacity(.15),
                                  ),
                                  child: Slider(
                                    min: 0,
                                    max: 5,
                                    divisions: 10,
                                    value: (filters.minRating ?? 0),
                                    onChanged: (v) => ctrl
                                        .setMinRating(v == 0 ? null : v),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _RatingFace(minRating: filters.minRating),
                          ],
                        ),
                      ),

                      const SizedBox(height: verticalSpacerDefault),

                      // Verified
                      _CardSection(
                        title: 'Verification',
                        trailing: Switch.adaptive(
                          value: filters.verifiedOnly,
                          onChanged: ctrl.setVerifiedOnly,
                          activeColor: owlPurple,
                          inactiveThumbColor: grey,
                          inactiveTrackColor: grey.withOpacity(.35),
                        ),
                        child: Text(
                          'Show only verified venues',
                          style: Styles.basicText,
                        ),
                      ),

                      const SizedBox(height: verticalSpacerDefault),

                      // Age restriction
                      _CardSection(
                        title: 'Age restriction',
                        trailing: Text(
                          filters.minAgeRestriction == null
                              ? 'Any'
                              : '${filters.minAgeRestriction!}+',
                          style: Styles.basicText.copyWith(
                            fontWeight: FontWeight.w600,
                            color: owlPurple,
                          ),
                        ),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: owlPurple,
                            inactiveTrackColor: grey.withOpacity(.3),
                            thumbColor: owlPurple,
                          ),
                          child: Slider(
                            min: 0,
                            max: 30,
                            divisions: 30,
                            value: (filters.minAgeRestriction ?? 0).toDouble(),
                            onChanged: (v) {
                              final age = v.round();
                              ctrl.setMinAgeRestriction(age == 0 ? null : age);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: verticalSpacerDefault),

                      // Price
                      _CardSection(
                        title: 'Entry price',
                        trailing: Text(
                          filters.maxEntryPrice == null
                              ? 'Any'
                              : '≤ ${filters.maxEntryPrice!.toStringAsFixed(0)}€',
                          style: Styles.basicText.copyWith(
                            fontWeight: FontWeight.w600,
                            color: owlPurple,
                          ),
                        ),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: owlPurple,
                            inactiveTrackColor: grey.withOpacity(.3),
                            thumbColor: owlPurple,
                          ),
                          child: Slider(
                            min: 0,
                            max: 50,
                            divisions: 50,
                            value: (filters.maxEntryPrice ?? 0),
                            onChanged: (v) {
                              ctrl.setMaxEntryPrice(v == 0 ? null : v);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: verticalSpacerDefault),

                      // Types
                      _CardSection(
                        title: 'Venue type',
                        trailing: Text(
                          filters.types.isEmpty
                              ? 'All'
                              : '${filters.types.length} selected',
                          style: Styles.basicText.copyWith(
                            fontWeight: FontWeight.w600,
                            color: owlPurple,
                          ),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // "All" chip
                            FilterChip(
                              label: const Text('All types'),
                              selected: filters.types.isEmpty,
                              onSelected: (_) {
                                if (filters.types.isNotEmpty) {
                                  for (final t in filters.types.toList()) {
                                    ctrl.toggleType(t);
                                  }
                                }
                              },
                              selectedColor: owlPurple,
                              backgroundColor: grey.withOpacity(.25),
                              side: BorderSide(
                                color:
                                filters.types.isEmpty ? owlPurple : grey,
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
                                  style: TextStyle(
                                      color: sel ? black : white),
                                ),
                                selected: sel,
                                onSelected: (_) => ctrl.toggleType(t),
                                selectedColor: owlPurple,
                                backgroundColor: grey.withOpacity(.25),
                                side: BorderSide(
                                  color: sel ? owlPurple : grey,
                                  width: 0.7,
                                ),
                                materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              );
                            }),
                          ],
                        ),
                      ),

                      // You can add a "Tags" section later that calls ctrl.toggleTag(tagId)
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
