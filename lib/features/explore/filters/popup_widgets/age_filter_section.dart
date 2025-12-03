// lib/features/explore/filters/popup_widgets/age_filter_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

import 'package:nightowlcode/data/providers/users/user_providers.dart';
import '../filter_controller.dart';
import 'card_section.dart';

// NOTE: also import the file where `ageRestrictionOptionsProvider` lives.
// e.g.:
// import '../age_options_provider.dart';

class AgeRestrictionFilterSection extends ConsumerWidget {
  const AgeRestrictionFilterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filtersProvider);
    final defaults = ref.watch(filterDefaultsProvider);
    final ctrl = ref.read(filtersProvider.notifier);

    // User prefs (gender etc.)
    final prefsAv = ref.watch(mePrefsAvProvider);
    final prefs = prefsAv.asData?.value;
    final gender = prefs?.gender ?? Gender.other;

    // Age restriction options available today (from venues)
    final ageOptionsRaw = ref.watch(ageRestrictionOptionsProvider);
    final ageOptions = [...ageOptionsRaw]..sort();

    // Fallback age (if somehow empty → 18)
    final fallbackAge = ageOptions.isNotEmpty ? ageOptions.first : 18;

    // Current effective age value (filter overrides defaults)
    final currentAgeValue =
        filters.minAgeRestriction ?? defaults.minAgeRestriction ?? fallbackAge;

    return CardSection(
      title: 'Age Restriction',
      trailing: Text(
        '${currentAgeValue}+',
        style: Styles.basicText.copyWith(
          fontWeight: FontWeight.w600,
          color: owlPurple,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              final ages = ageOptions.isNotEmpty ? ageOptions : <int>[18];

              int selectedIndex = 0;
              if (ages.length > 1) {
                int bestIdx = 0;
                int bestDiff = (ages[0] - currentAgeValue).abs();
                for (var i = 1; i < ages.length; i++) {
                  final diff = (ages[i] - currentAgeValue).abs();
                  if (diff < bestDiff) {
                    bestDiff = diff;
                    bestIdx = i;
                  }
                }
                selectedIndex = bestIdx;
              }

              final maxIndex = ages.length - 1;

              return SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: owlPurple,
                  inactiveTrackColor: grey.withOpacity(.3),
                  thumbColor: owlPurple,
                ),
                child: Slider(
                  min: 0,
                  max: maxIndex.toDouble(),
                  divisions: maxIndex > 0 ? maxIndex : null,
                  value: selectedIndex.toDouble(),
                  onChanged: (v) {
                    final idx = v.round().clamp(0, maxIndex);
                    final age = ages[idx];
                    ctrl.setMinAgeRestriction(age);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _AgeEmojiScale(
            minAge: currentAgeValue,
            ageOptions: ageOptions,
            gender: gender,
            onSelected: (age) => ctrl.setMinAgeRestriction(age),
          ),
        ],
      ),
    );
  }
}

/// Age emoji scale – age-based mapping, old face only at 25+
class _AgeEmojiScale extends StatelessWidget {
  final int? minAge;
  final List<int> ageOptions;
  final Gender gender;
  final ValueChanged<int> onSelected;

  const _AgeEmojiScale({
    required this.minAge,
    required this.ageOptions,
    required this.gender,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (ageOptions.isEmpty) {
      return const SizedBox.shrink();
    }

    final ages = [...ageOptions]..sort();
    final current = minAge ?? ages.first;

    // nearest index
    int selectedIndex = 0;
    int bestDiff = (ages[0] - current).abs();
    for (var i = 1; i < ages.length; i++) {
      final diff = (ages[i] - current).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        selectedIndex = i;
      }
    }

    // more varied emoji sets
    const maleEmojis = ['🧑‍🎓', '🧑', '🕺', '🧔', '👴'];
    const femaleEmojis = ['🧑‍🎓', '👩', '💃', '👩‍🦰', '👵'];

    final useFemale = gender != Gender.male;
    final base = useFemale ? femaleEmojis : maleEmojis;

    // age-based mapping – old face ONLY at 25+
    String emojiForAge(int age) {
      if (age >= 25) return base[4]; // 👴 / 👵
      if (age >= 23) return base[3]; // 🧔 / 👩‍🦰
      if (age >= 21) return base[2]; // 🕺 / 💃
      if (age >= 20) return base[1]; // 🧑 / 👩
      return base[0]; // 🧑‍🎓
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(ages.length, (i) {
          final age = ages[i];
          final emoji = emojiForAge(age);
          final isActive = i == selectedIndex;

          return GestureDetector(
            onTap: () => onSelected(age),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isActive ? owlPurple.withOpacity(.28) : transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                emoji,
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
