import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

// your avatar
import '../../../shared/constants/styles.dart';
import '../../../shared/reusable/ui/owl_popup.dart';
import '../../../shared/reusable/users/profile_picture_avatar.dart';
// your icon constants (chevrons etc.)
import 'package:nightowlcode/shared/constants/icons.dart';

/// Scrollable calendar with collapsible day sections.
/// - All days start collapsed to a fixed header height (uniform).
/// - Tap the header CONTAINER **or** the chevron to expand/collapse a day.
/// - Tap the date badge to show a PopupDialogDefault.
/// - Date badge shows a small fixed-size count chip just to its right.
class CalenderScreen extends StatefulWidget {
  const CalenderScreen({
    super.key,
    this.start,
    this.days = 60,
    this.schedules,
  });

  final DateTime? start;
  final int days;
  final List<DaySchedule>? schedules;

  @override
  State<CalenderScreen> createState() => _CalenderScreenState();
}

class _CalenderScreenState extends State<CalenderScreen> {
  late final List<DaySchedule> _days;
  late final List<bool> _expanded;

  // uniform minimal width for the date badge across all days
  late final double _badgeWidth;

  @override
  void initState() {
    super.initState();
    _days = widget.schedules ??
        DummyCalendarData.generate(
          from: (widget.start ?? DateTime.now()),
          days: widget.days,
        );
    _expanded = List<bool>.filled(_days.length, false, growable: false);

    _badgeWidth = _computeUniformBadgeWidth(); // compute once
  }

  // Smallest width that fits the widest date label, so all badges are equal.
  double _computeUniformBadgeWidth() {
    const labelStyle = TextStyle(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
    );
    double maxW = 0;
    for (final d in _days) {
      final label =
          '${_Fmt.dayShort(d.date).toUpperCase()} ${d.date.day} ${_Fmt.monthShort(d.date)}';
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (tp.width > maxW) maxW = tp.width;
    }
    const horizontalPadding = 24.0; // 12px left + 12px right
    const safety = 2.0; // small buffer
    return maxW + horizontalPadding + safety;
  }

// TODO Toggle view - calender vs list
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _DaySectionCard(
        schedule: _days[i],
        expanded: _expanded[i],
        onToggle: () => setState(() => _expanded[i] = !_expanded[i]),
        onTapDate: () => _onTapDate(context, _days[i].date),
        badgeWidth: _badgeWidth,
      ),
    );
  }

  Future<void> _onTapDate(BuildContext context, DateTime date) async {
    final day = _Fmt.dayShort(date).toUpperCase();
    final month = _Fmt.monthShort(date);
    await showDialog<bool>(
      context: context,
      builder: (_) => OwlPopup(
        title: '', //TODO
        children: [
          ListTile(
            title: Text('Are you going out on $day ${date.day} $month?',
                style: Styles.popupText), //TODO
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────── UI ─────────────────────────── */

class _DaySectionCard extends StatefulWidget {
  const _DaySectionCard({
    required this.schedule,
    required this.expanded,
    required this.onToggle,
    required this.onTapDate,
    required this.badgeWidth,
  });

  final DaySchedule schedule;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onTapDate;
  final double badgeWidth;

  @override
  State<_DaySectionCard> createState() => _DaySectionCardState();
}

class _DaySectionCardState extends State<_DaySectionCard>
    with TickerProviderStateMixin {
  static const double _kHeaderHeight = 64;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: black,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: grey, width: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Entire HEADER is tappable to toggle (container + chevron both work)
          SizedBox(
            height: _kHeaderHeight,
            child: Material(
              color: transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: widget.onToggle,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Row(
                    children: [
                      // Date badge is separately tappable (opens dialog)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: widget.onTapDate,
                        child: _DayDateBadge(
                          date: widget.schedule.date,
                          eventsCount: widget.schedule.events.length,
                          width: widget.badgeWidth,
                        ),
                      ),
                      const Spacer(),
                      // Avatar + "+AMOUNT" (using events count as proxy)
                      const ProfilePictureAvatar(size: 28),
                      const SizedBox(width: 8),
                      Text(
                        '+${widget.schedule.events.length}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Chevron (child gets the tap; parent InkWell won't fire)
                      Icon(
                        widget.expanded ? chevronUpIcon : chevronDownIcon,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Expandable content
          AnimatedSize(
            //TODO animate fold out and in.
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: widget.expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.schedule.events.isEmpty
                          ? const [_NoEventsTile()]
                          : widget.schedule.events
                              .map((e) => _EventTile(event: e))
                              .toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _DayDateBadge extends StatelessWidget {
  const _DayDateBadge({
    required this.date,
    required this.eventsCount,
    required this.width,
  });

  final DateTime date;
  final int eventsCount;
  final double width;

  static const double _kBadgeHeight = 36;
  static const double _kCountChipSize = 22;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final day = _Fmt.dayShort(date).toUpperCase();
    final month = _Fmt.monthShort(date);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fixed-size date pill (uniform minimal width across days)
        DecoratedBox(
          decoration: ShapeDecoration(
            color: cs.primaryContainer,
            shape: StadiumBorder(side: BorderSide(color: grey)),
          ),
          child: SizedBox(
            height: _kBadgeHeight,
            width: width,
            child: Center(
              child: Text(
                '$day ${date.day} $month',
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Small fixed-size count chip
        Container(
          width: _kCountChipSize,
          height: _kCountChipSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            border: Border.all(color: grey),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$eventsCount',
            style: TextStyle(
              color: cs.onSecondaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content on the left
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: grey, width: 0.7),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  if (event.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place_rounded,
                            size: 16, color: cs.secondary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            event.location!,
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (event.note != null) ...[
                    const SizedBox(height: 6),
                    Text(event.note!,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Time on the RIGHT (opposite side), right-aligned
          SizedBox(
            width: 72,
            child: Text(
              '${_Fmt.hhmm(event.start)}\n${_Fmt.hhmm(event.end)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoEventsTile extends StatelessWidget {
  const _NoEventsTile();

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink();
  }
}

/* ─────────────────────────── DATA ─────────────────────────── */

class DaySchedule {
  DaySchedule({required this.date, required this.events});
  final DateTime date;
  final List<CalendarEvent> events;
}

class CalendarEvent {
  CalendarEvent({
    required this.title,
    required this.start,
    required this.end,
    this.location,
    this.note,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final String? location;
  final String? note;
}

class DummyCalendarData {
  static final List<String> _titles = [
    'Daily stand-up',
    'Design review',
    'Client call',
    'Code pairing',
    'Team lunch',
    'Sprint planning',
    'QA testing',
    'Release prep',
    'Workout',
    'Coffee with Sam',
    '1:1 with manager',
  ];

  static final List<String> _places = [
    'Meeting Room A',
    'Zoom',
    'Café Corner',
    'Gym',
    'Open Space',
    'Room 3F',
  ];

  /// Generates [days] of deterministic dummy schedules starting at [from].
  static List<DaySchedule> generate({required DateTime from, int days = 30}) {
    final base = DateTime(from.year, from.month, from.day);
    final rng =
        Random(base.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay);

    return List.generate(days, (i) {
      final day = base.add(Duration(days: i));
      final int count = [0, 1, 2, 2, 3][rng.nextInt(5)];

      final events = List.generate(count, (_) {
        final startHour = 8 + rng.nextInt(9); // 08..16
        final startMin = rng.nextBool() ? 0 : 30;
        final durHours = 1 + rng.nextInt(2); // 1..2h
        final start =
            DateTime(day.year, day.month, day.day, startHour, startMin);
        final end = start.add(Duration(hours: durHours));
        final title = _titles[rng.nextInt(_titles.length)];
        final location =
            rng.nextBool() ? _places[rng.nextInt(_places.length)] : null;
        final note = rng.nextInt(5) == 0 ? 'Bring notes & laptop' : null;
        return CalendarEvent(
          title: title,
          start: start,
          end: end,
          location: location,
          note: note,
        );
      })
        ..sort((a, b) => a.start.compareTo(b.start));

      return DaySchedule(date: day, events: events);
    });
  }
}

/* ─────────────────────────── HELPERS ─────────────────────────── */

class _Fmt {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  static String dayShort(DateTime d) => _days[(d.weekday - 1) % 7];
  static String monthShort(DateTime d) => _months[d.month - 1];
  static String _two(int n) => n < 10 ? '0$n' : '$n';
  static String hhmm(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}';
}
