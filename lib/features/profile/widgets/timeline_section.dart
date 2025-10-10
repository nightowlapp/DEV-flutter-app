import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/styles.dart';

class WeekHours {
  final int week; // ISO week number, e.g. 36
  final double hours; // hours spent that week
  const WeekHours({required this.week, required this.hours});
}

class TimelineSection extends StatelessWidget {
  const TimelineSection({
    super.key,
    required this.data,
    this.height = 180,
    this.barWidth = 20,
    this.spacing = 12,
    this.yTicks = 5,
    this.barColor = const Color(0xFFFF8C00),
    this.gridColor = const Color(0x33FFFFFF),
    this.borderColor = const Color(0x44FFFFFF),
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(8),
    this.leftGutter = 30,
    this.bottomGutter = 30, // minimum; real gutter is computed
    this.yLabelStyle,
    this.xLabelStyle,
    this.title = 'My Timeline',
    this.leftCaption = '1331',
    this.rightCaption = 'See All',
    this.onRightTap,
    this.onBarTap,
  });

  final List<WeekHours> data;
  final double height;
  final double barWidth;
  final double spacing;
  final int yTicks;
  final Color barColor;
  final Color gridColor;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsets padding;
  final double leftGutter;
  final double bottomGutter; // acts as a floor
  final TextStyle? yLabelStyle;
  final TextStyle? xLabelStyle;

  final String title;
  final String? leftCaption;
  final String? rightCaption;
  final VoidCallback? onRightTap;

  final ValueChanged<WeekHours>? onBarTap;

  @override
  Widget build(BuildContext context) {
    // Header
    final header = SizedBox(
      height: 32,
      child: Stack(
        children: [
          if (leftCaption != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(leftCaption!, style: Styles.basicText),
              ),
            ),
          Align(
            alignment: Alignment.center,
            child: Text(title,
                style: Styles.basicText, textAlign: TextAlign.center),
          ),
          if (rightCaption != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onRightTap,
                child: Text(rightCaption!, style: Styles.basicText),
              ),
            ),
        ],
      ),
    );

    // Clean data
    final cleaned = data
        .map((e) => WeekHours(
            week: e.week,
            hours: (e.hours.isFinite && e.hours > 0) ? e.hours : 0))
        .toList(growable: false);

    if (cleaned.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 8),
          _chartFrame(
            height: height,
            child: const Center(
                child:
                    Text('No data', style: TextStyle(color: Colors.white54))),
          ),
        ],
      );
    }

    // Axis/grid
    final safeTicks = yTicks.clamp(2, 10);
    final maxVal = cleaned.fold<double>(0, (m, v) => math.max(m, v.hours));
    final yMax = _niceCeil(maxVal <= 0 ? 1 : maxVal);
    final divisions = (safeTicks - 1);
    final yLabels = List.generate(safeTicks, (i) => (yMax * (i / divisions)));

    final yStyle =
        yLabelStyle ?? const TextStyle(fontSize: 11, color: Colors.white70);
    final xStyle =
        xLabelStyle ?? const TextStyle(fontSize: 11, color: Colors.white70);

    // --- FIX: compute a safe gutter for X labels (prevents bottom overflow)
    final xSampleH = _textHeight(context, xStyle, '88');
    final unitH = _textHeight(context, xStyle, 'week #');
    final xGutter = math.max(bottomGutter, math.max(xSampleH, unitH) + 8);

    // Layout sizes
    final safeHeight = height.clamp(100.0, double.infinity);
    final contentHeight =
        (safeHeight - padding.vertical).clamp(60.0, double.infinity);
    final barAreaHeight =
        (contentHeight - xGutter).clamp(40.0, double.infinity);

    // width for all bars
    final totalBars = cleaned.length;
    final chartWidth = (totalBars * barWidth) + ((totalBars - 1) * spacing);

    final chart = _chartFrame(
      height: safeHeight,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            // Y axis
            SizedBox(
              width: leftGutter,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('hrs', style: yStyle),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: yLabels.reversed
                          .map((v) => Align(
                                alignment: Alignment.centerRight,
                                child:
                                    Text(v.round().toString(), style: yStyle),
                              ))
                          .toList(growable: false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Scrollable plot
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: chartWidth,
                  height: contentHeight,
                  child: Column(
                    children: [
                      // Grid + bars
                      SizedBox(
                        height: barAreaHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // horizontal grid
                            Column(
                              children: List.generate(safeTicks, (i) {
                                return Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: i == 0
                                              ? Colors.transparent
                                              : gridColor,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            // vertical grid aligned to bars
                            IgnorePointer(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (int i = 0; i < totalBars; i++) ...[
                                    SizedBox(
                                      width: barWidth,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                                color: gridColor, width: 0.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (i != totalBars - 1)
                                      SizedBox(width: spacing),
                                  ],
                                ],
                              ),
                            ),
                            // bars
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  for (int i = 0; i < totalBars; i++) ...[
                                    _Bar(
                                      hours: cleaned[i].hours,
                                      max: yMax,
                                      areaHeight: barAreaHeight - 1,
                                      width: barWidth,
                                      color: barColor,
                                      onTap: onBarTap == null
                                          ? null
                                          : () => onBarTap!(cleaned[i]),
                                      semanticsLabel:
                                          'Week ${cleaned[i].week}, ${cleaned[i].hours.toStringAsFixed(1)} hours',
                                    ),
                                    if (i != totalBars - 1)
                                      SizedBox(width: spacing),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // X axis labels + unit
                      SizedBox(
                        height: xGutter,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (int i = 0; i < totalBars; i++) ...[
                              SizedBox(
                                width: barWidth,
                                child: Center(
                                  child: Text('${cleaned[i].week}',
                                      style: xStyle,
                                      overflow: TextOverflow.visible),
                                ),
                              ),
                              if (i != totalBars - 1) SizedBox(width: spacing),
                            ],
                            const SizedBox(width: 6),
                            Text('week #', style: xStyle),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 8),
        chart,
      ],
    );
  }

  static double _niceCeil(double x) {
    if (x <= 0) return 1;
    final exp = (math.log(x) / math.ln10).floor();
    final f = x / math.pow(10.0, exp);
    double nice;
    if (f <= 1)
      nice = 1;
    else if (f <= 2)
      nice = 2;
    else if (f <= 5)
      nice = 5;
    else
      nice = 10;
    return (nice * math.pow(10.0, exp)).toDouble();
  }

  double _textHeight(BuildContext context, TextStyle style, String sample) {
    final scale = MediaQuery.textScaleFactorOf(context);
    final tp = TextPainter(
      text: TextSpan(text: sample, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaleFactor: scale,
    )..layout();
    return tp.size.height;
  }

  Widget _chartFrame({required double height, required Widget child}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.hours,
    required this.max,
    required this.areaHeight,
    required this.width,
    required this.color,
    this.onTap,
    this.semanticsLabel,
  });

  final double hours;
  final double max;
  final double areaHeight;
  final double width;
  final Color color;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final h =
        (max <= 0 ? 0 : (hours / max) * areaHeight).clamp(0.0, areaHeight);

    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      child: SizedBox(
        width: width,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: h.toDouble()),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Container(
                    width: width,
                    height: value,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
