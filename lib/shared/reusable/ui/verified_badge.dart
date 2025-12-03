import 'package:flutter/material.dart';

// lib/shared/reusable/ui/verified_badge.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: black,
        borderRadius: BorderRadius.circular(borderRadiusSmall),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(checkCircleIcon, color: green, size: iconSizeMedium),
          Text('Verified',
              style: Styles.smallText
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 6)),
        ],
      ),
    );
  }
}

enum Corner { topLeft, topRight, bottomLeft, bottomRight }

class CornerBadgeOverlay extends StatelessWidget {
  const CornerBadgeOverlay({
    super.key,
    required this.child,
    required this.show,
    required this.badge,
    this.corner = Corner.topRight,
    this.padding = const EdgeInsets.only(top: 0, right: 0),
    this.ignorePointer = true,
  });

  final Widget child;
  final bool show;
  final Widget badge;
  final Corner corner;
  final EdgeInsets padding;
  final bool ignorePointer;

  @override
  Widget build(BuildContext context) {
    final align = switch (corner) {
      Corner.topLeft => Alignment.topLeft,
      Corner.topRight => Alignment.topRight,
      Corner.bottomLeft => Alignment.bottomLeft,
      Corner.bottomRight => Alignment.bottomRight,
    };

    // Keep the badge fixed inside the viewport (not scrollable), and
    // consistently offset by SafeArea + padding.
    return Stack(
      children: [
        child,
        if (show)
          SafeArea(
            top: corner == Corner.topLeft || corner == Corner.topRight,
            bottom: corner == Corner.bottomLeft || corner == Corner.bottomRight,
            left: corner == Corner.topLeft || corner == Corner.bottomLeft,
            right: corner == Corner.topRight || corner == Corner.bottomRight,
            child: Align(
              alignment: align,
              child: IgnorePointer(
                ignoring: ignorePointer,
                child: Padding(padding: padding, child: badge),
              ),
            ),
          ),
      ],
    );
  }
}
