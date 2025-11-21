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
    final defaults = ref.watch(filterDefaultsProvider);
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
                      // ---- Distance ----
                      _CardSection(
                        title: 'Distance',
                        trailing: _DistanceLabel(
                          currentKm: filters.maxDistanceKm,
                          defaultKm: defaults.maxDistanceKm,
                          onTap: () async {
                            final initial =
                                filters.maxDistanceKm ??
                                    defaults.maxDistanceKm ??
                                    15;
                            final result = await _promptForNumber(
                              context: context,
                              title: 'Max distance (km)',
                              initial: initial,
                              min: 0,
                              max: 60,
                              suffix: 'km',
                            );
                            if (result == null) return;
                            ctrl.setMaxDistanceKm(
                                result <= 0 ? null : result);
                          },
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: owlPurple,
                                inactiveTrackColor: grey.withOpacity(.3),
                                thumbColor: owlPurple,
                                overlayColor:
                                owlPurple.withOpacity(.15),
                              ),
                              child: Slider(
                                min: 0,
                                max: 60,
                                divisions: 60,
                                value: filters.maxDistanceKm ?? 0,
                                onChanged: (v) =>
                                    ctrl.setMaxDistanceKm(
                                        v <= 0 ? null : v),
                              ),
                            ),
                            const _EmojiScale(),
                          ],
                        ),
                      ),

                      const SizedBox(height: verticalSpacerDefault),

                      // ---- Rating ----
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
                                    activeTrackColor:
                                    grey.withOpacity(.35),
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
                                    onChanged: (v) => ctrl.setMinRating(
                                        v == 0 ? null : v),
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

                      // ---- Age restriction (18–25) ----
                      _CardSection(
                        title: 'Age restriction',
                        trailing: Text(
                          filters.minAgeRestriction == null
                              ? '18+'
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
                            min: 18,
                            max: 25,
                            divisions: 7,
                            value: (filters.minAgeRestriction ?? 18)
                                .toDouble(),
                            onChanged: (v) {
                              final age = v.round();
                              ctrl.setMinAgeRestriction(age);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: verticalSpacerDefault),

                      // ---- Venue type (sideways scroll with icons) ----
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
                        child: SizedBox(
                          height: 100,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                _AllTypesFilterChip(
                                  selected: filters.types.isEmpty,
                                  onTap: () {
                                    if (filters.types.isNotEmpty) {
                                      for (final t
                                      in filters.types.toList()) {
                                        ctrl.toggleType(t);
                                      }
                                    }
                                  },
                                ),
                                const SizedBox(width: 12),
                                for (final type in VenueType.values
                                    .where((t) =>
                                t != VenueType.unknown)) ...[
                                  _TypeFilterChip(
                                    type: type,
                                    selected: filters.types
                                        .contains(type),
                                    onTap: () => ctrl.toggleType(type),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
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
    return Container(
      padding: const EdgeInsets.all(horizontalSpacerDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: white,
                  fontWeight: FontWeight.w700,
                ),
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
                  fontWeight:
                  isEmoji ? FontWeight.w600 : FontWeight.w400,
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
      face = '😊';
    } else if (r >= 2.0) {
      face = '🙂';
    } else if (r > 0) {
      face = '🙁';
    } else {
      face = '⭐';
    }
    return Text(face);
  }
}

// ---- Distance label with tap-to-edit ----

class _DistanceLabel extends StatelessWidget {
  final double? currentKm;
  final double? defaultKm;
  final VoidCallback onTap;

  const _DistanceLabel({
    required this.currentKm,
    required this.defaultKm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    if (currentKm == null) {
      text = 'Off';
    } else if (defaultKm != null &&
        (currentKm! - defaultKm!).abs() < 0.5) {
      text = 'Default (${currentKm!.round()} km)';
    } else if (currentKm! >= 60) {
      text = '60+ km';
    } else {
      text = '${currentKm!.round()} km';
    }

    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: Styles.basicText.copyWith(
          fontWeight: FontWeight.w600,
          color: owlPurple,
        ),
      ),
    );
  }
}

// ---- Venue type chips ----

class _AllTypesFilterChip extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _AllTypesFilterChip({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? owlPurple : grey.withOpacity(.25);
    final fg = selected ? black : white;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: bg,
            child: Icon(
              Icons.all_inclusive,
              size: 22,
              color: fg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All',
            style: Styles.basicText.copyWith(
              fontSize: 11,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  final VenueType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeFilterChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = Utility.formatString(type.name);
    final bg = selected ? owlPurple : owlPurple.withOpacity(0.12);
    final iconColor = selected ? black : owlPurple;
    final textColor = selected ? black : white;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: bg,
            child: Icon(
              type.icon, // extension on VenueType (same as in VenuesSection)
              size: 22,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Styles.basicText.copyWith(
              fontSize: 11,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---- Simple numeric input dialog ----

Future<double?> _promptForNumber({
  required BuildContext context,
  required String title,
  required double initial,
  required double min,
  required double max,
  String? suffix,
}) async {
  final controller =
  TextEditingController(text: initial.toStringAsFixed(0));

  return showDialog<double>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: black,
        title: Text(title, style: Styles.popupHeader),
        content: TextField(
          controller: controller,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: white),
          decoration: InputDecoration(
            suffixText: suffix,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final raw = controller.text.replaceAll(',', '.');
              final v = double.tryParse(raw);
              if (v == null) {
                Navigator.of(ctx).pop();
                return;
              }
              double clamped = v;
              if (clamped < min) clamped = min;
              if (clamped > max) clamped = max;
              Navigator.of(ctx).pop(clamped);
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
