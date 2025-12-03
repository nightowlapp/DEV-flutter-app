// lib/features/explore/filters/popup_widgets/venue_type_filter_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

import '../filter_controller.dart';
import 'card_section.dart';

const double _kVenueChipWidth = 60.0;
const Duration _kVenueChipAnimDuration = Duration(milliseconds: 620);

class VenueTypeFilterSection extends ConsumerWidget {
  const VenueTypeFilterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filtersProvider);
    final ctrl = ref.read(filtersProvider.notifier);

    return CardSection(
      title: 'Venue Type',
      contentHorizontalPadding: 8,
      trailing: Text(
        filters.types.isEmpty ? 'All' : '${filters.types.length}',
        style: Styles.basicText.copyWith(
          fontWeight: FontWeight.w600,
          color: owlPurple,
        ),
      ),
      child: SizedBox(
        height: 80,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: AnimatedSwitcher(
            duration: _kVenueChipAnimDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Row(
              key: ValueKey(filters.types.hashCode),
              children: () {
                final allTypes = VenueType.values
                    .where((t) => t != VenueType.unknown)
                    .toList();

                final selectedTypes = <VenueType>[];
                final unselectedTypes = <VenueType>[];

                for (final t in allTypes) {
                  if (filters.types.contains(t)) {
                    selectedTypes.add(t);
                  } else {
                    unselectedTypes.add(t);
                  }
                }

                const gap = SizedBox(width: 4);
                final children = <Widget>[];

                children.add(const SizedBox(width: 4));

                children.add(
                  SizedBox(
                    width: _kVenueChipWidth,
                    child: _AllTypesFilterChip(
                      selected: filters.types.isEmpty,
                      onTap: () {
                        if (filters.types.isNotEmpty) {
                          for (final t in filters.types.toList()) {
                            ctrl.toggleType(t);
                          }
                        }
                      },
                    ),
                  ),
                );

                children.add(gap);

                for (final type in selectedTypes) {
                  children.add(
                    SizedBox(
                      width: _kVenueChipWidth,
                      child: _TypeFilterChip(
                        key: ValueKey(type),
                        type: type,
                        selected: true,
                        onTap: () => ctrl.toggleType(type),
                      ),
                    ),
                  );
                  children.add(gap);
                }

                if (selectedTypes.isNotEmpty && unselectedTypes.isNotEmpty) {
                  children.add(gap);
                }

                for (final type in unselectedTypes) {
                  children.add(
                    SizedBox(
                      width: _kVenueChipWidth,
                      child: _TypeFilterChip(
                        key: ValueKey(type),
                        type: type,
                        selected: false,
                        onTap: () => ctrl.toggleType(type),
                      ),
                    ),
                  );
                  children.add(gap);
                }

                children.add(const SizedBox(width: 4));
                return children;
              }(),
            ),
          ),
        ),
      ),
    );
  }
}

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
    void handleTap() => onTap();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: handleTap,
          child: AnimatedContainer(
            duration: _kVenueChipAnimDuration,
            curve: Curves.easeInOutCubic,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
            ),
            child: const Icon(
              Icons.all_inclusive,
              size: 20,
              color: white,
            ),
          ),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: handleTap,
          child: SizedBox(
            height: 14,
            child: Center(
              child: Text(
                'All',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Styles.smallText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  final VenueType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeFilterChip({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = Utility.formatString(type.name);
    final bg = selected ? owlPurple : black;
    final iconColor = selected ? white : owlPurple;

    void handleTap() => onTap();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: handleTap,
          child: AnimatedContainer(
            duration: _kVenueChipAnimDuration,
            curve: Curves.easeInOutCubic,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
            ),
            child: Icon(
              type.icon,
              size: 20,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: handleTap,
          child: SizedBox(
            height: 14,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Styles.smallText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
