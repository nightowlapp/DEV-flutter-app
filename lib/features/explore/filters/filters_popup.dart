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

    // Raw effective distance from filters or defaults (may be 0)
    final effectiveDistanceKm =
        filters.maxDistanceKm ?? defaults.maxDistanceKm ?? 0.0;

    // Value we actually show in UI (never < 1)
    final uiDistanceKm = (effectiveDistanceKm <= 0
        ? (defaults.maxDistanceKm ?? 15.0)
        : effectiveDistanceKm)
        .clamp(1.0, 60.0);

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
              crossAxisAlignment: CrossAxisAlignment.center,
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
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 3,
                radius: Radius.circular(borderRadiusDefault),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: verticalSpacerDefault,
                  ),
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
                            final initial = uiDistanceKm;
                            final result = await _promptForNumber(
                              context: context,
                              title: 'Max distance (km)',
                              initial: initial,
                              min: 1,
                              max: 60,
                              suffix: 'km',
                            );
                            if (result == null) return;

                            if (result <= 0) {
                              // 0 → "back to default" (use user prefs)
                              ctrl.clearMaxDistance();
                            } else {
                              ctrl.setMaxDistanceKm(result);
                            }
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
                                overlayColor: owlPurple.withOpacity(.15),
                              ),
                              child: Slider(
                                min: 1,
                                max: 60,
                                divisions: 59,
                                value: uiDistanceKm,
                                onChanged: (v) {
                                  ctrl.setMaxDistanceKm(v);
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            _DistanceEmojiScale(
                              distanceKm: uiDistanceKm,
                              onSelected: (km) => ctrl.setMaxDistanceKm(km),
                            ),
                          ],
                        ),
                      ),

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: owlPurple,
                                      inactiveTrackColor:
                                      grey.withOpacity(.35),
                                      thumbColor: owlPurple,
                                      overlayColor:
                                      owlPurple.withOpacity(.15),
                                    ),
                                    child: Slider(
                                      min: 0,
                                      max: 4.5,
                                      divisions: 9,
                                      // Any => 0 (far left, empty)
                                      value: filters.minRating ?? 0,
                                      onChanged: (v) => ctrl.setMinRating(
                                        v == 0 ? null : v,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _RatingFace(minRating: filters.minRating),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _RatingEmojiScale(
                              minRating: filters.minRating,
                              onSelected: (v) => ctrl.setMinRating(v),
                            ),
                          ],
                        ),
                      ),

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
                            value:
                            (filters.minAgeRestriction ?? 18).toDouble(),
                            onChanged: (v) {
                              final age = v.round();
                              ctrl.setMinAgeRestriction(age);
                            },
                          ),
                        ),
                      ),

                      // ---- Venue type (sideways scroll with icons) ----
                      _CardSection(
                        title: 'Venue type',
                        trailing: Text(
                          filters.types.isEmpty
                              ? 'All'
                              : '${filters.types.length}',
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
                                    .where(
                                        (t) => t != VenueType.unknown)) ...[
                                  _TypeFilterChip(
                                    type: type,
                                    selected: filters.types.contains(type),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: ctrl.reset,
                    child: Text(
                      'Reset Filters',
                      style: Styles.smallText.copyWith(color: red),
                    ),
                  ),  TextButton(
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

// Tighter section layout: title + content + small gap + divider
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            horizontalSpacerLarge,
            horizontalSpacerSmall,
            horizontalSpacerLarge,
            horizontalSpacerSmall,
          ),
          child: Row(
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
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            horizontalSpacerDefault,
            6,
            horizontalSpacerDefault,
            0,
          ),
          child: child,
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalSpacerDefault,
          ),
          child: Divider(
            color: grey,
            height: 0, // no extra vertical padding from Divider itself
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

/// Distance emoji scale – behaves like Rating emoji scale:
/// - One emoji always active (nearest to distanceKm)
/// - Clicking emoji sets the distance (and moves the slider)
class _DistanceEmojiScale extends StatelessWidget {
  final double distanceKm;
  final ValueChanged<double> onSelected;

  const _DistanceEmojiScale({
    required this.distanceKm,
    required this.onSelected,
  });

  // Single source of truth for emojis + their corresponding km values
  static const List<_DistanceEmojiOption> _options = [
    _DistanceEmojiOption('🚶', 1.5),   // very close
    _DistanceEmojiOption('🚲', 5.0),   // nearby
    _DistanceEmojiOption('🚌', 20.0),  // in the city
    _DistanceEmojiOption('🚄', 40.0),  // out of town
    _DistanceEmojiOption('✈️', 60.0),  // far away / max
  ];

  int _selectedIndexForDistance(double value) {
    double d = value;
    if (d <= 0) d = _options.first.km;

    // Plane only when at max (60+)
    if (d >= 60) {
      return _options.length - 1; // ✈️
    }

    // Find nearest option among all EXCEPT plane
    int bestIndex = 0;
    double bestDiff = (d - _options[0].km).abs();

    for (var i = 1; i < _options.length - 1; i++) { // <-- note -1 here
      final diff = (d - _options[i].km).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestIndex = i;
      }
    }

    return bestIndex;
  }


  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndexForDistance(distanceKm);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_options.length, (i) {
          final opt = _options[i];
          final isActive = i == selectedIndex;

          return GestureDetector(
            onTap: () => onSelected(opt.km),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? owlPurple.withOpacity(.28)
                    : transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                opt.emoji,
                style: TextStyle(
                  fontSize: isActive ? iconSizeMedium : iconSizeDefault,
                  color: isActive ? owlPurple : white.withOpacity(.85),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DistanceEmojiOption {
  final String emoji;
  final double km;

  const _DistanceEmojiOption(this.emoji, this.km);
}

class _RatingFace extends StatelessWidget {
  const _RatingFace({required this.minRating});
  final double? minRating;

  @override
  Widget build(BuildContext context) {
    final r = minRating ?? 0;
    String face;
    if (r >= 4.0) {
      face = '😍';
    } else if (r >= 3.0) {
      face = '😊';
    } else if (r >= 2.0) {
      face = '🙂';
    } else if (r > 0) {
      face = '😐';
    } else {
      face = '⭐';
    }
    // currently hidden – you can show it if you want
    return const SizedBox.shrink();
  }
}

class _RatingEmojiScale extends StatelessWidget {
  final double? minRating;
  final ValueChanged<double?> onSelected;

  const _RatingEmojiScale({
    required this.minRating,
    required this.onSelected,
  });

  // Single source of truth for emojis + their values
  static const List<_RatingEmojiOption> _options = [
    _RatingEmojiOption('⭐', null), // Any
    _RatingEmojiOption('😐', 2.0),
    _RatingEmojiOption('🙂', 3.0),
    _RatingEmojiOption('😊', 3.5),
    _RatingEmojiOption('😍', 4.0),
  ];

  int _selectedIndexForRating(double? rating) {
    final r = rating ?? 0;

    // Any / off
    if (r <= 0) return 0;

    // Find the option (from index 1..) with the nearest value
    int bestIndex = 1;
    double bestDiff = double.infinity;

    for (var i = 1; i < _options.length; i++) {
      final v = _options[i].value!;
      final diff = (v - r).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestIndex = i;
      }
    }

    return bestIndex;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndexForRating(minRating);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_options.length, (i) {
          final opt = _options[i];
          final isActive = i == selectedIndex;

          return GestureDetector(
            onTap: () => onSelected(opt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? owlPurple.withOpacity(.28)
                    : transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                opt.emoji,
                style: TextStyle(
                  fontSize: isActive ? iconSizeMedium : iconSizeDefault,
                  color: isActive ? owlPurple : white.withOpacity(.85),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RatingEmojiOption {
  final String emoji;
  final double? value;

  const _RatingEmojiOption(this.emoji, this.value);
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
    // If the user hasn't picked a custom distance yet,
    // show their preference-based default instead of "Off".
    final double? baseKm = currentKm ?? defaultKm;

    final double km = baseKm!; // non-null here

    final String displayKm =
    km % 1 == 0 ? km.toInt().toString() : km.toStringAsFixed(1);    String text;

    if (baseKm == null) {
      // Should only happen while prefs are still loading.
      text = 'Any distance';
    } else if (baseKm >= 60) {
      // Right-most position is "60+ km"
      text = '60+ km';
    } else {
      text = '$displayKm km';
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
