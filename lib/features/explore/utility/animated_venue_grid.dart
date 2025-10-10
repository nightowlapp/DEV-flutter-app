// lib/features/explore/presentation/widgets/animated_venues_grid.dart
import 'dart:math' as math;
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:flutter/material.dart';
import 'package:nightowlcode/features/explore/widgets/venue_main_screen.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/features/explore/widgets/venue_card.dart';
import 'package:nightowlcode/data/services/media_existence.dart';

class AnimatedVenuesGrid extends StatefulWidget {
  const AnimatedVenuesGrid({
    super.key,
    required this.venues,
    required this.mediaById,
    required this.userLoc,
    this.initialVisible = 12,
    this.pageSize = 12,
    this.onEndReached,
    this.datasetKey, // optional: parent can force-reset paging by changing this
  });

  final List<Venue> venues; // already ranked
  final Map<String, VenueMediaHealth> mediaById;
  final LatLng? userLoc;
  final int initialVisible;
  final int pageSize;
  final VoidCallback? onEndReached;
  final String? datasetKey;

  @override
  State<AnimatedVenuesGrid> createState() => _AnimatedVenuesGridState();
}

class _AnimatedVenuesGridState extends State<AnimatedVenuesGrid> {
  late int _visible;
  late String _fingerprint; // auto fingerprint to detect dataset changes

  @override
  void initState() {
    super.initState();
    _visible = math.min(widget.initialVisible, widget.venues.length);
    _fingerprint = _makeFingerprint(widget.venues, widget.datasetKey);
  }

  @override
  void didUpdateWidget(covariant AnimatedVenuesGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newFp = _makeFingerprint(widget.venues, widget.datasetKey);
    final changedDataset = newFp != _fingerprint;

    if (changedDataset) {
      // Dataset identity changed (e.g., search cleared/changed) → reset paging
      _visible = math.min(widget.initialVisible, widget.venues.length);
      _fingerprint = newFp;
    } else {
      // Same dataset → just clamp if list shrank
      _visible = math.min(_visible, widget.venues.length);
    }
  }

  String _makeFingerprint(List<Venue> v, String? externalKey) {
    if (externalKey != null && externalKey.isNotEmpty) return externalKey;
    if (v.isEmpty) return 'len:0';
    final len = v.length;
    final first = v.first.id;
    final last = v.last.id;
    // include a short head to be robust on small edits
    final headCount = len < 8 ? len : 8;
    final head = v.take(headCount).map((e) => e.id).join(',');
    return 'len:$len|first:$first|last:$last|head:$head';
  }

  void _maybeGrow(ScrollNotification n) {
    if (n.metrics.pixels > n.metrics.maxScrollExtent - 200 &&
        _visible < widget.venues.length) {
      setState(() {
        _visible = math.min(widget.venues.length, _visible + widget.pageSize);
      });
      widget.onEndReached?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleVenues = widget.venues.take(_visible).toList();
    final rows = _toRows(visibleVenues);

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        _maybeGrow(n);
        return false;
      },
      child: ImplicitlyAnimatedList<_VenueRow>(
        items: rows,
        areItemsTheSame: (a, b) => a.key == b.key,
        itemBuilder: (context, animation, row, index) {
          return SizeFadeTransition(
            animation: animation,
            curve: Curves.easeOut,
            sizeFraction: 0.85,
            child: Padding(
              padding: const EdgeInsets.only(
                left: horizontalSpacerDefault,
                right: horizontalSpacerDefault,
                bottom: horizontalSpacerDefault,
              ),
              child: _RowOfTwo(
                left: row.left,
                right: row.right,
                mediaById: widget.mediaById,
                userLoc: widget.userLoc,
              ),
            ),
          );
        },
        removeItemBuilder: (context, animation, oldRow) {
          return SizeFadeTransition(
            animation: animation,
            curve: Curves.easeIn,
            sizeFraction: 0.85,
            child: Opacity(
              opacity: 0.5,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: horizontalSpacerDefault,
                  right: horizontalSpacerDefault,
                  bottom: horizontalSpacerDefault,
                ),
                child: _RowOfTwo(
                  left: oldRow.left,
                  right: oldRow.right,
                  mediaById: widget.mediaById,
                  userLoc: widget.userLoc,
                ),
              ),
            ),
          );
        },
        insertDuration: const Duration(milliseconds: 500),
        removeDuration: const Duration(milliseconds: 500),
        updateDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}

class _RowOfTwo extends StatelessWidget {
  const _RowOfTwo({
    required this.left,
    required this.right,
    required this.mediaById,
    required this.userLoc,
  });

  final Venue? left;
  final Venue? right;
  final Map<String, VenueMediaHealth> mediaById;
  final LatLng? userLoc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _AnimatedVenueCell(
                venue: left, mediaById: mediaById, userLoc: userLoc)),
        const SizedBox(width: horizontalSpacerLarge),
        Expanded(
            child: _AnimatedVenueCell(
                venue: right, mediaById: mediaById, userLoc: userLoc)),
      ],
    );
  }
}

class _AnimatedVenueCell extends StatelessWidget {
  const _AnimatedVenueCell({
    required this.venue,
    required this.mediaById,
    required this.userLoc,
  });

  final Venue? venue;
  final Map<String, VenueMediaHealth> mediaById;
  final LatLng? userLoc;

  @override
  Widget build(BuildContext context) {
    final switchKey = venue?.id ?? '__empty__';
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) {
        final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        final slide =
            Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero)
                .animate(fade);
        return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child));
      },
      child: venue == null
          ? const SizedBox(key: ValueKey('__empty__'), height: 0)
          : VenueCard(
              key: ValueKey(switchKey),
              venue: venue!,
              userLocation: userLoc,
              media: mediaById[venue!.id],
              onTap: () {
                context.pushVenue(
                  venue!,
                  media: mediaById[venue!.id],
                  userLoc: userLoc,
                );
              },
            ),
    );
  }
}

class _VenueRow {
  final Venue? left;
  final Venue? right;
  const _VenueRow(this.left, this.right);
  String get key => '${left?.id ?? "_"}|${right?.id ?? "_"}';
}

List<_VenueRow> _toRows(List<Venue> venues) {
  final rows = <_VenueRow>[];
  for (var i = 0; i < venues.length; i += 2) {
    final left = venues[i];
    final right = (i + 1 < venues.length) ? venues[i + 1] : null;
    rows.add(_VenueRow(left, right));
  }
  return rows;
}
