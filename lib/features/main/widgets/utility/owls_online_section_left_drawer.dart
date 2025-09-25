import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import '../../../../shared/constants/icons.dart';

/// Owls online vs total users (progress bar + stats)
/// Percentage is shown centered inside the bar.
class OwlsOnlineSectionLeftDrawer extends StatelessWidget {
  const OwlsOnlineSectionLeftDrawer({
    super.key,
    required this.online,
    required this.total,
  });

  final int online;
  final int total;

  @override
  Widget build(BuildContext context) {
    final int safeTotal = total <= 0 ? 1 : total;
    final int safeOnline = online.clamp(0, safeTotal);
    final double ratio = safeOnline / safeTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Center(child: Text('Owls Online', style: Styles.boldText)),
            Align(
              alignment: Alignment.centerLeft,
              child: Icon(globeIcon, color: owlPurple, size: iconSizeDefault),
            ),
          ],
        ),

        const SizedBox(height: verticalSpacerSmall),

        // Progress bar with centered percentage label
        _AnimatedLinearBar(
          value: ratio,
          background: grey.withOpacity(.35),
          foreground: owlPurple,
          radius: BorderRadius.circular(999),
        ),

        const SizedBox(height: verticalSpacerSmall),

        // Count (kept below the bar)
        Center(
          child: Text(
            '${_fmt(safeOnline)} / ${_fmt(safeTotal)}',
            style: Styles.boldText,
          ),
        ),
      ],
    );
  }
}

/// Nicely animated linear bar (no extra packages)
/// Now renders the percentage label in the center of the bar.
class _AnimatedLinearBar extends StatelessWidget {
  const _AnimatedLinearBar({
    required this.value,
    this.height = 100, //TODO maybe cool?
    // this.height = 18,
    required this.background,
    required this.foreground,
    required this.radius,
  });

  final double value; // 0..1
  final double height;
  final Color background;
  final Color foreground;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        decoration: BoxDecoration(color: background),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: v),
              builder: (context, t, _) {
                final pct = (t * 100).clamp(0, 100).toStringAsFixed(1);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Filled part
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: constraints.maxWidth * t,
                        decoration: BoxDecoration(
                          color: foreground,
                          borderRadius: radius,
                          boxShadow: [
                            BoxShadow(
                              color: foreground.withOpacity(.35),
                              blurRadius: 10,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Subtle glossy highlight
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              white.withOpacity(.08),
                              white.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Centered percentage label
                    Center(
                      child: Semantics(
                        label: 'Online percentage',
                        value: '$pct percent',
                        child: Text(
                          '$pct%',
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: white,
                            fontWeight: FontWeight.w800,
                            fontSize: (height * 0.7).clamp(10, 16).toDouble(),
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 2,
                                offset: Offset(0, 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Simple thousands-separator without importing intl
String _fmt(int n) {
  final s = n.toString();
  final r = s.split('').reversed.toList();
  final out = StringBuffer();
  for (int i = 0; i < r.length; i++) {
    if (i != 0 && i % 3 == 0) out.write(',');
    out.write(r[i]);
  }
  return out.toString().split('').reversed.join();
}
