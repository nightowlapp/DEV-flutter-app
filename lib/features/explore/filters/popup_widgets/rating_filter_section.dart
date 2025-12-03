// lib/features/explore/filters/popup_widgets/rating_filter_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/styles.dart';

import '../filter_controller.dart';
import 'card_section.dart';

class RatingFilterSection extends ConsumerWidget {
  const RatingFilterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filtersProvider);
    final ctrl = ref.read(filtersProvider.notifier);

    return CardSection(
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
                    inactiveTrackColor: grey.withOpacity(.35),
                    thumbColor: owlPurple,
                    overlayColor: owlPurple.withOpacity(.15),
                  ),
                  child: Slider(
                    min: 0,
                    max: 4.5,
                    divisions: 9,
                    value: filters.minRating ?? 0,
                    onChanged: (v) => ctrl.setMinRating(v == 0 ? null : v),
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
    return const SizedBox.shrink(); // keep hidden for now
  }
}

class _RatingEmojiScale extends StatelessWidget {
  final double? minRating;
  final ValueChanged<double?> onSelected;

  const _RatingEmojiScale({
    required this.minRating,
    required this.onSelected,
  });

  static const List<_RatingEmojiOption> _options = [
    _RatingEmojiOption('⭐', null),
    _RatingEmojiOption('😐', 2.0),
    _RatingEmojiOption('🙂', 3.0),
    _RatingEmojiOption('😊', 3.5),
    _RatingEmojiOption('😍', 4.0),
  ];

  int _selectedIndexForRating(double? rating) {
    final r = rating ?? 0;
    if (r <= 0) return 0;

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
                color: isActive ? owlPurple.withOpacity(.28) : transparent,
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
