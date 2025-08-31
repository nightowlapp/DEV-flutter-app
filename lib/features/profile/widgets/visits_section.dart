import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../shared/constants/styles.dart';
import '../../../shared/constants/values.dart'; // verticalSpacerSmall

class VenueVisit {
  final String name;
  final String image; // asset or network
  final int visits;
  const VenueVisit({required this.name, required this.image, required this.visits});
}

/// "My Visits" — never overflows, keeps dummy data, and matches your header spacing.
/// - Caps the list height to: min(parent space, desired height, content height)
/// - If only a few items, the section shrinks; otherwise it becomes scrollable.
class VisitsSection extends StatelessWidget {
  const VisitsSection({
    super.key,
    this.data = const [],
    this.badgeColor = const Color(0xFFFF8C00),
    this.avatarRadius = 18,
    this.height, // desired max list height; if null defaults to 240
    this.demoWhenEmpty = true,
    this.title = 'My Visits',
    this.rightCaption = 'See All',
    this.onRightTap,
  });

  final List<VenueVisit> data;
  final Color badgeColor;
  final double avatarRadius;
  final double? height;
  final bool demoWhenEmpty;

  // Header
  final String title;
  final String rightCaption;
  final VoidCallback? onRightTap;

  static const List<VenueVisit> _demo = [
    VenueVisit(name: 'Owl Bar',    image: 'assets/nightowl/test.png', visits: 12),
    VenueVisit(name: 'Night Lab',  image: 'assets/nightowl/test.png', visits: 9),
    VenueVisit(name: 'Bass House', image: 'assets/nightowl/test.png', visits: 7),
    VenueVisit(name: 'Echo Club',  image: 'assets/nightowl/test.png', visits: 6),
    VenueVisit(name: 'Neon Room',  image: 'assets/nightowl/test.png', visits: 4),
    VenueVisit(name: 'GrooveDen',  image: 'assets/nightowl/test.png', visits: 3),
    VenueVisit(name: 'Lunar Pub',  image: 'assets/nightowl/test.png', visits: 2),
    VenueVisit(name: 'Afterglow',  image: 'assets/nightowl/test.png', visits: 1),
  ];

  static const double _kHeaderHeight = 32;

  @override
  Widget build(BuildContext context) {
    final items = (data.isEmpty && demoWhenEmpty) ? _demo : data;

    // keep your numbers behavior (+323)
    final totalVisits = items.fold<int>(0, (sum, v) => sum + v.visits) + 323;
    final leftText = '$totalVisits';

    // Desired max list height (soft cap)
    final wanted = (height ?? 240).clamp(80, 6000);

    // Row height ~= avatar diameter (never smaller than 36 for touch)
    final rowHeight = math.max(avatarRadius * 2, 36.0);
    // Content height if we showed all rows without scrolling
    final contentHeight = items.isEmpty
        ? rowHeight
        : (items.length * rowHeight) + ((items.length - 1) * 8.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        // If parent is height-bounded (e.g., in a Column sharing space),
        // honor the available space to prevent overflow.
        final parentCap = constraints.hasBoundedHeight
            ? math.max(0.0, constraints.maxHeight - _kHeaderHeight - verticalSpacerSmall)
            : double.infinity;

        final listHeight = [
          wanted.toDouble(),
          contentHeight,
          parentCap,
        ].where((v) => v.isFinite).reduce(math.min);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header (same layout/spacing as AchievementsSection)
            SizedBox(
              height: _kHeaderHeight,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(leftText, style: Styles.basicTextHeader),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text(title, style: Styles.basicTextHeader),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: onRightTap,
                      child: Text(rightCaption, style: Styles.basicTextHeader),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: verticalSpacerSmall),

            // Content
            if (items.isEmpty)
              SizedBox(
                height: rowHeight,
                child: Center(
                  child: Text('No visits yet', style: Styles.basicTextHeader),
                ),
              )
            else
              SizedBox(
                height: listHeight,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  // fixed row extent -> smoother scrolling & accurate height calc
                  itemBuilder: (context, index) {
                    final v = items[index];
                    return SizedBox(
                      height: rowHeight,
                      child: Row(
                        children: [
                          _Avatar(image: v.image, radius: avatarRadius),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              v.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: badgeColor, width: 1),
                            ),
                            child: Text(
                              '${v.visits}x',
                              style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                ),
              ),
          ],
        );
      },
    );
  }
}

/* ───────────────────────── Helper: resilient avatar ───────────────────────── */
class _Avatar extends StatelessWidget {
  const _Avatar({required this.image, required this.radius});

  final String image;
  final double radius;

  bool get _isNetwork => image.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final dim = radius * 2;

    final Widget img = _isNetwork
        ? Image.network(
      image,
      width: dim,
      height: dim,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(dim),
    )
        : Image.asset(
      image,
      width: dim,
      height: dim,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(dim),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(dim), // full circle
      child: img,
    );
  }

  Widget _fallback(double dim) => Container(
    width: dim,
    height: dim,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white12,
      borderRadius: BorderRadius.circular(dim),
    ),
    child: const Icon(Icons.location_city, color: Colors.white54, size: 18),
  );
}
