// lib/features/explore/presentation/widgets/filters_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

import 'filter_controller.dart';

Future<void> showFiltersSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: black,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadiusDefault)),
    ),
    builder: (_) => const _FiltersSheetBody(),
    isScrollControlled: true,
  );
}

class _FiltersSheetBody extends ConsumerWidget {
  const _FiltersSheetBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filtersProvider);
    final ctrl = ref.read(filtersProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        horizontalSpacerDefault,
        horizontalSpacerDefault,
        horizontalSpacerDefault,
        horizontalSpacerLarge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grabber
          Center(
            child: Container(
              width: 44, height: 5,
              margin: const EdgeInsets.only(bottom: verticalSpacerSmall),
              decoration: BoxDecoration(
                color: grey.withOpacity(.6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          Row(
            children: [
              const Text('Filters', style: TextStyle(color: white, fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: ctrl.reset,
                child: const Text('Reset', style: TextStyle(color: owlOrange)),
              ),
              const SizedBox(width: 4),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: owlOrange, foregroundColor: black),
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: verticalSpacerDefault),

          // Open now
          SwitchListTile(
            value: filters.openNowOnly,
            onChanged: ctrl.setOpenNow,
            activeColor: owlOrange,
            title: const Text('Open now', style: TextStyle(color: white)),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: verticalSpacerDefault),

          // Rating
          _Section(
            title: 'Minimum rating',
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    min: 0, max: 5, divisions: 10,
                    value: (filters.minRating ?? 0),
                    label: (filters.minRating ?? 0).toStringAsFixed(1),
                    activeColor: owlOrange,
                    onChanged: (v) => ctrl.setMinRating(v == 0 ? null : v),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    filters.minRating?.toStringAsFixed(1) ?? '—',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: verticalSpacerDefault),

          // Distance
          _Section(
            title: 'Max distance',
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    min: 0, max: 60, divisions: 60,
                    value: (filters.maxDistanceKm ?? 0),
                    label: filters.maxDistanceKm == null ? 'off' : '${filters.maxDistanceKm!.round()} km',
                    activeColor: owlOrange,
                    onChanged: (v) => ctrl.setMaxDistanceKm(v == 0 ? null : v),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    filters.maxDistanceKm == null ? 'off' : '${filters.maxDistanceKm!.round()} km',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: verticalSpacerDefault),

          // Types (compact chips)
          _Section(
            title: 'Types',
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: VenueType.values
                  .where((t) => t != VenueType.unknown)
                  .map((t) {
                final sel = filters.types.contains(t);
                return FilterChip(
                  label: Text(t.name, style: TextStyle(color: sel ? black : white)),
                  selected: sel,
                  onSelected: (_) => ctrl.toggleType(t),
                  selectedColor: owlOrange,
                  backgroundColor: grey.withOpacity(.25),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: verticalSpacerDefault),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
