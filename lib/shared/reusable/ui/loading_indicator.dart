// bottom_logo_spinner.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/assets.dart';

/// Bottom-aligned spinner that uses your logo(s) as a rotating circle.
///
/// Spins sideways (around Y axis) to the right and swaps between your icons.
/// By default it cycles through:
///   - ImagePaths.logoLeft
///   - ImagePaths.logoUp
///   - ImagePaths.logoRight
///   - ImagePaths.logoDown
///
/// Example:
/// LoadingIndicator()
/// LoadingIndicator(logoSequence: [ImagePaths.logoLeft, ImagePaths.logoRight])
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.logoAsset = ImagePaths.logoColored,
    this.logoSequence = const [
      ImagePaths.logoColored,
      // ImagePaths.logoUpBackground,
      // ImagePaths.logoRightBackground,
      // ImagePaths.logoDownBackground,
    ],
    this.size = 85.0,
    this.duration = const Duration(milliseconds: 2500),
    this.bottomPadding = 0,
    this.borderWidth = 0,
    this.enableGlow = true,
  });

  /// Fallback single logo (used if [logoSequence] is empty).
  final String logoAsset;

  /// Sequence of logos to cycle through as it spins sideways.
  final List<String> logoSequence;

  final double size;
  final Duration duration;
  final double bottomPadding;
  final double borderWidth;
  final bool enableGlow;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSecondary;

    final logos =
        (logoSequence.isNotEmpty) ? logoSequence : <String>[logoAsset];

    return IgnorePointer(
      ignoring: true,
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: enableGlow
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.28),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ]
                    : const [],
              ),
              child: _RotatingCircle(
                duration: duration,
                size: size,
                color: color,
                borderWidth: borderWidth,
                logoAssets: logos,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Spins the logo(s) sideways (Y-axis) and switches the asset along the way.
class _RotatingCircle extends StatefulWidget {
  const _RotatingCircle({
    required this.duration,
    required this.size,
    required this.color,
    required this.borderWidth,
    required this.logoAssets,
  });

  final Duration duration;
  final double size;
  final Color color;
  final double borderWidth;
  final List<String> logoAssets;

  @override
  State<_RotatingCircle> createState() => _RotatingCircleState();
}

class _RotatingCircleState extends State<_RotatingCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)..repeat();

  static const double _twoPi = 6.283185307179586; // 2 * pi

  @override
  Widget build(BuildContext context) {
    final assets = widget.logoAssets.isEmpty
        ? <String>[ImagePaths.logoColored]
        : widget.logoAssets;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value; // 0..1
        // Spin sideways to the right:
        final angle = -t * _twoPi;

        // Decide which logo to show based on where we are in the turn.
        final segmentCount = assets.length;
        final segment = (t * segmentCount).floor() % segmentCount;
        final currentAsset = assets[segment];

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..rotateY(angle),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: widget.borderWidth > 0
                    ? Border.all(color: widget.color, width: widget.borderWidth)
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                currentAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.circle,
                  color: widget.color,
                  size: widget.size,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
