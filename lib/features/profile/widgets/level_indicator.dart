import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

// TODO implement a question mark or whatever far right with popup that informs on how to get exp.

class LevelIndicator extends StatelessWidget {
  final String levelLabel; // e.g. 'Level 7'
  final int current;
  final int total;
  final double height;
  final Color trackColor;
  final Color fillColor;
  final Gradient? gradient;
  final double radius;
  final Duration duration;
  final Curve curve;
  final TextStyle? textStyle;
  final double minFillPx;
  final VoidCallback? onTap;

  const LevelIndicator({
    super.key,
    required this.levelLabel,
    required this.current,
    required this.total,
    this.height = 24,
    this.trackColor = const Color(0xFF222222),
    this.fillColor = const Color(0xFFFF8C00),
    this.gradient,
    this.radius = 999,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeOut,
    this.textStyle,
    this.minFillPx = 2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final v = (total <= 0) ? 0.0 : (current / total).clamp(0.0, 1.0);
    final br = BorderRadius.circular(radius);

    return Semantics(
      label: levelLabel,
      value: '$current of $total',
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: SizedBox(
          width: double.infinity, // as wide as possible
          child: ClipRRect(
            borderRadius: br,
            child: Stack(
              children: [
                Container(
                  height: height,
                  decoration:
                  BoxDecoration(color: trackColor, borderRadius: br),
                ),
                LayoutBuilder(
                  builder: (context, c) {
                    // build-up fill inside with color
                    final w =
                    v == 0 ? 0.0 : math.max(minFillPx, c.maxWidth * v);
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: duration,
                        curve: curve,
                        width: w, // <-- progress width (not infinity)
                        height: height,
                        decoration: BoxDecoration(
                          color: gradient == null ? fillColor : null,
                          gradient: gradient,
                          borderRadius: br,
                        ),
                      ),
                    );
                  },
                ),
                // Labels: level mid-left, XP mid-right (now spaced evenly)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly, // each side of middle
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          levelLabel,
                          style: textStyle ??
                              const TextStyle(
                                color: white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                        ),
                        Text(
                          '$current / $total',
                          style: textStyle ??
                              const TextStyle(
                                color: white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
