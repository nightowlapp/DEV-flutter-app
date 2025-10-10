// lib/features/navigation/presentation/navigation_banner.dart
import 'package:flutter/material.dart';
import '../../../data/services/navigation/navigation_service.dart';

class NavigationBanner extends StatelessWidget {
  final double distanceMeters;
  final double durationSeconds;
  final String nextInstruction;
  final NavProfile mode;
  final VoidCallback onStop;

  const NavigationBanner({
    super.key,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.nextInstruction,
    required this.mode,
    required this.onStop,
  });

  IconData get _icon => switch (mode) {
    NavProfile.walking => Icons.directions_walk_rounded,
    NavProfile.cycling => Icons.directions_bike_rounded,
    NavProfile.driving => Icons.directions_car_rounded,
  };

  Color get _accent => switch (mode) {
    NavProfile.walking => const Color(0xFF22C55E), // green
    NavProfile.cycling => const Color(0xFFF59E0B), // amber
    NavProfile.driving => const Color(0xFF3B82F6), // blue
  };

  String _fmtDist(double m) {
    if (m < 1000) return '${m.round()} m';
    final km = m / 1000.0;
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
    // tweak thresholds if you like
  }

  String _fmtEta(double s) {
    final mins = (s / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60, m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      bottom: true,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        height: 64, // fixed compact height
        decoration: BoxDecoration(
          color: const Color(0xF0151516), // dark glass-ish
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            // mode chip
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _accent.withOpacity(.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accent.withOpacity(.35)),
              ),
              child: Icon(_icon, color: _accent, size: 22),
            ),
            const SizedBox(width: 10),
            // main info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distance · ETA
                  Text(
                    '${_fmtDist(distanceMeters)} · ${_fmtEta(durationSeconds)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Next instruction (single line)
                  Text(
                    nextInstruction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            // stop
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: onStop,
              tooltip: 'Stop navigation',
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}
