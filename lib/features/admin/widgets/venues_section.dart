import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/utility/utility.dart';
import 'package:nightowlcode/models/venues/venue.dart';

import '../../../data/providers/venues/venue_providers.dart';

class VenuesSection extends ConsumerWidget {
  const VenuesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Minimal DB: use SSO list instead of Firestore streams
    final List<Venue> venues = ref.watch(allVenuesListProvider);
    final allVenues = venues.length;

    // ----- Aggregate: by type -----
    final typeCounts = <VenueType, int>{};
    // ----- Aggregate: by country (ISO code) -----
    final countryCounts = <String, int>{};

    for (final v in venues) {
      // Types
      typeCounts[v.type] = (typeCounts[v.type] ?? 0) + 1;

      // Countries (normalize)
      final code =
          (v.countryCode.isEmpty ? 'unknown' : v.countryCode.toUpperCase());
      countryCounts[code] = (countryCounts[code] ?? 0) + 1;
    }

    final sortedTypes = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedCountries = countryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isEmpty = allVenues == 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'Total Venues',
                    style: Styles.basicText.copyWith(color: adminColor),
                  ),
                  Text(
                    '$allVenues',
                    style: Styles.basicText.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isEmpty)
                Center(
                  child: Text(
                    'No venues yet',
                    style: Styles.basicText.copyWith(
                      color: adminColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else ...[
                // ---------- Types ----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Types',
                      style: Styles.basicText,
                    ),
                    Text(
                      '${sortedTypes.length}',
                      style: Styles.basicText.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        for (final entry in sortedTypes) ...[
                          _TypeStatChip(
                            type: entry.key,
                            count: entry.value,
                          ),
                          const SizedBox(width: 12), // not too much distance
                        ],
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ---------- Countries ----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Countries',
                      style: Styles.basicText,
                    ),
                    Text(
                      '${sortedCountries.length}',
                      style: Styles.basicText.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        for (final entry in sortedCountries) ...[
                          _CountryStatChip(
                            countryCode: entry.key,
                            count: entry.value,
                          ),
                          const SizedBox(width: 12),
                        ],
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TypeStatChip extends StatelessWidget {
  final VenueType type;
  final int count;

  const _TypeStatChip({
    required this.type,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final label = Utility.formatString(type.name);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: owlPurple.withOpacity(0.12),
            child: Icon(
              type.icon, // from VenueTypeIconX
              size: 22,
              color: adminColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Styles.basicText.copyWith(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$count',
            style: Styles.basicText.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryStatChip extends StatelessWidget {
  final String countryCode;
  final int count;

  const _CountryStatChip({
    required this.countryCode,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final code = countryCode.toUpperCase();

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: owlPurple.withOpacity(0.12),
            child: Text(
              code.length > 3 ? code.substring(0, 3) : code,
              style: Styles.basicText.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: adminColor,
              ),
            ),
          ),
          Text(
            '$count',
            style: Styles.basicText.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}
