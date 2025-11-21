// lib/features/explore/filters/popup_widgets/distance_filter_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/reusable/ui/popup_dialog_default.dart';

import '../filter_controller.dart';
import 'card_section.dart';

class DistanceFilterSection extends ConsumerWidget {
  const DistanceFilterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filtersProvider);
    final defaults = ref.watch(filterDefaultsProvider);
    final ctrl = ref.read(filtersProvider.notifier);

    final effectiveDistanceKm =
        filters.maxDistanceKm ?? defaults.maxDistanceKm ?? 0.0;

    final uiDistanceKm = (effectiveDistanceKm <= 0
        ? (defaults.maxDistanceKm ?? 15.0)
        : effectiveDistanceKm)
        .clamp(1.0, 60.0);

    return CardSection(
      title: 'Max Distance',
      trailing: _DistanceLabel(
        currentKm: filters.maxDistanceKm,
        defaultKm: defaults.maxDistanceKm,
        onTap: () async {
          final initial = uiDistanceKm;
          final result = await _promptForNumber(
            context: context,
            title: 'Set Max distance',
            initial: initial,
            min: 1,
            max: 60,
            suffix: 'km',
          );
          if (result == null) return;

          if (result <= 0) {
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
              onChanged: (v) => ctrl.setMaxDistanceKm(v),
            ),
          ),
          const SizedBox(height: 8),
          _DistanceEmojiScale(
            distanceKm: uiDistanceKm,
            onSelected: (km) => ctrl.setMaxDistanceKm(km),
          ),
        ],
      ),
    );
  }
}

/// Distance emoji scale
class _DistanceEmojiScale extends StatelessWidget {
  final double distanceKm;
  final ValueChanged<double> onSelected;

  const _DistanceEmojiScale({
    required this.distanceKm,
    required this.onSelected,
  });

  static const List<_DistanceEmojiOption> _options = [
    _DistanceEmojiOption('🚶', 1.5),
    _DistanceEmojiOption('🚲', 5.0),
    _DistanceEmojiOption('🚌', 20.0),
    _DistanceEmojiOption('🚄', 40.0),
    _DistanceEmojiOption('✈️', 60.0),
  ];

  int _selectedIndexForDistance(double value) {
    double d = value;
    if (d <= 0) d = _options.first.km;

    if (d >= 60) return _options.length - 1;

    int bestIndex = 0;
    double bestDiff = (d - _options[0].km).abs();

    for (var i = 1; i < _options.length - 1; i++) {
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
                color:
                isActive ? owlPurple.withOpacity(.28) : transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                opt.emoji,
                style: TextStyle(
                  fontSize:
                  isActive ? iconSizeMedium : iconSizeDefault,
                  color: isActive
                      ? owlPurple
                      : white.withOpacity(.85),
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
    final double? baseKm = currentKm ?? defaultKm;
    String text;

    if (baseKm == null) {
      text = 'Any distance';
    } else if (baseKm >= 60) {
      text = '60+ km';
    } else {
      final km = baseKm;
      final displayKm =
      km % 1 == 0 ? km.toInt().toString() : km.toStringAsFixed(1);
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

// simple numeric dialog, same behaviour as before
Future<double?> _promptForNumber({
  required BuildContext context,
  required String title,
  required double initial,
  required double min,
  required double max,
  String? suffix,
}) async {
  final controller = TextEditingController(
    text: initial.toStringAsFixed(0),
  );

  return showDialog<double>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return PopupDialogDefault(
        title: title,
        children: [
          const SizedBox(height: verticalSpacerDefault),
          TextField(
            controller: controller,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: white),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Max distance',
              labelStyle: Styles.popupText.copyWith(
                color: grey.withOpacity(0.8),
              ),
              suffixText: suffix,
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: grey),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: owlPurple),
              ),
            ),
          ),
          const SizedBox(height: verticalSpacerDefault),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: grey),
                ),
              ),
              const SizedBox(width: 12),
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
                child: const Text(
                  'Set',
                  style: TextStyle(color: owlPurple),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
