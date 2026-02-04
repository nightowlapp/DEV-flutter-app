import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/users/visit_session.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/buttons.dart';
import 'package:nightowlcode/shared/reusable/ui/owl_popup.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

/// Shows a popup with details for visit sessions to a venue.
Future<void> showVisitSessionsPopup(
  BuildContext context, {
  required Venue venue,
  required List<VisitSession> sessions,
}) async {
  // Sort by enteredAt desc (newest first)
  final items = [...sessions]
    ..sort((a, b) => (b.enteredAt ?? DateTime(0))
        .compareTo(a.enteredAt ?? DateTime(0)));

  String two(int n) => n < 10 ? '0$n' : '$n';
  String yy2(int year) => (year % 100).toString().padLeft(2, '0');
  String fmt(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.toLocal();
    return '${two(d.hour)}:${two(d.minute)}';
  }
  String fmtDay(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.toLocal();
       return '${d.year}/${two(d.month)}/${two(d.day)}';
  }

  // Header label: dd/mm/yy OR dd - dd2 mm/yy if the visit spans days
  String headerDayRangeLabel(VisitSession s) {
    final start = (s.enteredAt ?? DateTime.now()).toLocal();
    final end = (s.exitedAt ?? s.enteredAt ?? DateTime.now()).toLocal();
    final sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
    if (sameDay) {
      return '${two(start.day)}/${two(start.month)}/${yy2(start.year)}';
    }
    // crossed midnight (or multiple days): dd - dd2 mm/yy (use end's mm/yy)
    return '${two(start.day)} - ${two(end.day)} ${two(end.month)}/${yy2(end.year)}';
  }

  String duration(VisitSession s) {
    final start = s.enteredAt;
    final end = s.exitedAt;
    if (start == null) return '—';
    final stop = end ?? DateTime.now();
    final diff = stop.difference(start);
    if (diff.inMinutes < 1) return '< 1 min';
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    if (h <= 0) return '${m}m';
    return '${h}h ${m}m';
  }

  await showDialog(
    context: context,
    builder: (ctx) {
    

      return OwlPopup(
        title: 'Visits at ${venue.displayName.isNotEmpty ? venue.displayName : venue.name}',

        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No visit sessions found', style: Styles.basicText),
            )
          else
            ...items.asMap().entries.take(20).map((entry) {
              final i = entry.key;
              final s = entry.value;
              final ongoing = s.exitedAt == null;
              final visitNumber = items.length - i; // newest has highest number
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: grey, width: 0.7),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#$visitNumber Visit',
                          style: Styles.basicTextHeader.copyWith(
                            color: ongoing ? blue : white,
                          ),
                        ),
                        const Spacer(),
                          if (s.enteredAt != null)
                            Text(
                              // headerDayRangeLabel(s),
                              Utility.formatTimeAgo(s.enteredAt!),
                              style: Styles.basicText,
                            ),

                                                  // Text(
                        //   s.source.isNotEmpty ? Utility.formatString(s.source) : '',
                        //   style:
                        //       Styles.smallText.copyWith(color: Colors.white70),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${fmt(s.enteredAt)} - ${s.exitedAt != null ? fmt(s.exitedAt) : 'now'}',
                                                  style: Styles.basicText,

                        ),
                        Spacer(),
Text(duration(s),
                            style: Styles.basicText.copyWith(color: purple)),
                   
                      ],
                    ),
                    // Row( //TODO later. Change time of visit and delete visit entirely
                    //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //   children: [
                    //     OwlButton(label: 'Delete', onPressed: () {},),
                    //     OwlButton(label: 'Edit', onPressed: () {},)
                    //   ],
                    // )
                  ],
                ),
              );
            }),
        ],
      );
    },
  );
}
