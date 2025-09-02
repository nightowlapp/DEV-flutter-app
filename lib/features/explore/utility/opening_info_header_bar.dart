// lib/shared/widgets/opening_info_header_bar.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart'; // OpeningHours, extensions

class OpeningInfoHeaderBar extends StatefulWidget {
  const OpeningInfoHeaderBar({
    super.key,
    required this.openingHours,
    required this.defaultAgeRestriction,
    this.initiallyExpanded = false,
    this.now,                               // pass venue-local now if you have it
    this.dayWidth = 100,
    this.rangeWidth = 110,
    this.borderColor = grey,
    this.textColor = white,
  });

  final OpeningHours openingHours;
  final int defaultAgeRestriction;

  /// If provided, used as “venue local now”; otherwise DateTime.now()
  final DateTime? now;

  final bool initiallyExpanded;

  // Layout knobs
  final double dayWidth;
  final double rangeWidth;
  final Color borderColor;
  final Color textColor;

  @override
  State<OpeningInfoHeaderBar> createState() => _OpeningInfoHeaderBarState();
}

class _OpeningInfoHeaderBarState extends State<OpeningInfoHeaderBar> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  // --- small helper for a superscript +1 ---
  InlineSpan _plusOne(TextStyle base, Color color) => WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    child: Transform.translate(
      offset: const Offset(1, -4),
      child: Text('+1', style: Styles.smallText.copyWith(fontWeight: FontWeight.w600)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final oh = widget.openingHours;
    final now = (widget.now ?? DateTime.now()).toLocal();

    // If currently open due to yesterday's overnight, show yesterday’s row.
    final status = oh.statusAt(now);
    final displayDate = (status.phase == OpeningPhase.open && status.fromYesterday)
      ? now.subtract(const Duration(days: 1))
      : now;

    final headerLabel = DateFormat.EEEE().format(displayDate);

    // Reuse your formatter for the header day
    final todayParts = oh.todayRangeParts24h(localNow: displayDate);
    final ageToday = oh.activeAgeRestriction(displayDate) ?? widget.defaultAgeRestriction;

    final base = Styles.boldText.copyWith(letterSpacing: 1);

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: widget.borderColor, width: 0.7),
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ----- Header row (today or yesterday if overnight) -----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: widget.dayWidth, child: Text(headerLabel, style: base.copyWith(fontSize: fontSizeMedium))),
                SizedBox(
                  width: widget.rangeWidth,
                  child: todayParts.isClosed
                    ? Text('Closed', style: base)
                    : RichText(
                      text: TextSpan(
                        style: base,
                        children: [
                          TextSpan(text: '${todayParts.open} - ${todayParts.close}'),
                          if (todayParts.nextDay) _plusOne(base, widget.textColor),
                        ],
                      ),
                    ),
                ),
                Text('$ageToday+', style: base),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 16,
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: widget.textColor),
                ),
              ],
            ),

            // ----- Next 6 days -----
            if (_isExpanded) ...[
              Column(
                children: List.generate(6, (i) {
                    final d = displayDate.add(Duration(days: i + 1));
                    final label = DateFormat.EEEE().format(d);
                    final p = oh.todayRangeParts24h(localNow: d);
                    final age = oh.activeAgeRestriction(d) ?? widget.defaultAgeRestriction;;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: widget.dayWidth, child: Text(label, style: base)),
                          SizedBox(
                            width: widget.rangeWidth,
                            child: p.isClosed
                              ? Text('Closed', style: base)
                              : RichText(
                                text: TextSpan(
                                  style: base,
                                  children: [
                                    TextSpan(text: '${p.open} - ${p.close}'),
                                    if (p.nextDay) _plusOne(base, widget.textColor),
                                  ],
                                ),
                              ),
                          ),
                          Text(p.isClosed ? '      ' :
                              '$age+', style: base),
                          const SizedBox(width: 50), // reserved for future "busy" meter, etc.
                        ],

                      ),
                    );
                  }
                ),

              ),
            ],
          ],
        ),
      ),
    );
  }
}
