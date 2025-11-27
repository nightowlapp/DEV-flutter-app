import 'package:flutter/material.dart';

import 'package:nightowlcode/models/navigation/nav_models.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

import '../../../data/services/navigation/navigation_service.dart';
import '../../../shared/constants/styles.dart';

class NavigationBanner extends StatelessWidget {
  const NavigationBanner({
    super.key,
    required this.activeRoute,
    required this.navDest,
    required this.navProfile,
    required this.onStop,
    required this.onToggleMute,
    required this.isMuted,
    required this.initialDistance,
  });

  final NavRoute? activeRoute;
  final Venue? navDest;
  final NavProfile navProfile;
  final VoidCallback onStop;
  final VoidCallback onToggleMute;
  final bool isMuted;
  final double? initialDistance;

  IconData _modeIcon(NavProfile p) {
    switch (p) {
      case NavProfile.walking:
        return Icons.directions_walk_rounded;
      case NavProfile.cycling:
        return Icons.directions_bike_rounded;
      case NavProfile.driving:
        return Icons.directions_car_rounded;
    }
  }

  Color _accent(NavProfile p) {
    switch (p) {
      case NavProfile.walking:
        return const Color(0xFF22C55E); // green
      case NavProfile.cycling:
        return const Color(0xFFF59E0B); // amber
      case NavProfile.driving:
        return const Color(0xFF3B82F6); // blue
    }
  }

  String _fmtMeters(double meters) {
    final m = meters.round();
    if (m < 1000) return '$m m';
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
  }

  String _fmtEta(double seconds) {
    if (seconds <= 0) return '—';
    final mins = (seconds / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return h >= 9 ? '9+ hr' : (m == 0 ? '${h}h' : '${h}h ${m}m');
  }

  String _fmtArrivalClock(BuildContext context, double seconds) {
    if (seconds <= 0) return 'now';
    final dt = DateTime.now().add(Duration(seconds: seconds.round()));
    final tod = TimeOfDay.fromDateTime(dt);
    final use24h = MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
    final loc = MaterialLocalizations.of(context);
    final clock = loc.formatTimeOfDay(tod, alwaysUse24HourFormat: use24h);
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return clock; // today
    } else if (dt.difference(DateTime(now.year, now.month, now.day)).inDays == 1) {
      return clock;
    } else {
      return '${dt.month}/${dt.day} $clock';
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = activeRoute;
    final dest = navDest;
    if (r == null) return const SizedBox.shrink();
    final dist = _fmtMeters(r.distanceMeters);
    final travelTime = _fmtEta(r.durationSeconds);
    final eta = _fmtArrivalClock(context, r.durationSeconds);
    final step = r.steps.isNotEmpty ? r.steps.first.instruction : '';
    final destName = dest?.displayName ?? '';
    final accentColor = _accent(navProfile);
    final progress = (initialDistance != null && initialDistance! > 0)
        ? (1 - (r.distanceMeters / initialDistance!)).clamp(0.0, 1.0)
        : 0.0;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Stack(
            children: [
              Material(
                color: black,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: accentColor.withOpacity(0.35)),
                                ),
                                child: Icon(_modeIcon(navProfile),
                                    color: accentColor, size: iconSizeDefault),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: onToggleMute,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isMuted
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                  color: white,
                                  size: iconSizeDefault,
                                ),
                              ),
                            ),
                          ]),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(travelTime, style: Styles.basicText),
                          const SizedBox(height: 6),
                          Text(dist,
                              style: Styles.smallText
                                  .copyWith(fontSize: fontSizeSmaller)),
                          const SizedBox(height: 6),
                          Text(eta,
                              style: Styles.smallText
                                  .copyWith(fontSize: fontSizeSmaller)),
                        ],
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          step,
                          style: Styles.basicText,
                          textAlign: TextAlign.left,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 110,
                right: 40,
                top: 20,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: greyLighter,
                  borderRadius: BorderRadius.circular(borderRadiusDefault),
                  valueColor: AlwaysStoppedAnimation<Color>(owlPurple),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Row(
                  children: [
                    Text('To ', style: Styles.basicText),
                    Text(
                      destName,
                      style: Styles.basicText.copyWith(color: owlPurple),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: InkWell(
                  onTap: onStop,
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(Icons.close_rounded,
                      color: greyLighter, size: iconSizeDefault),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}