// bottom_logo_spinner.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nightowlcode/assets.dart';

/// Bottom-aligned spinner that uses your logo as the rotating circle.
/// Place it anywhere; it overlays and pins itself to the bottom.
///
/// Example:
/// BottomLogoSpinner(logoAsset: ImagePaths.logo)
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.logoAsset = ImagePaths.logo,
    this.size = 50.0,
    this.duration = const Duration(milliseconds: 1000),
    this.bottomPadding = 0,
    this.borderWidth = 0,
    this.enableGlow = true,
  });

  final String logoAsset;
  final double size;
  final Duration duration;
  final double bottomPadding;
  final double borderWidth;
  final bool enableGlow;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSecondary;

    return SpinKitRotatingCircle(
      color: color,
      duration: const Duration(seconds: 2),
    );
    IgnorePointer(
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
                        )
                      ]
                    : const [],
              ),
              child: _RotatingCircle(
                duration: duration,
                size: size,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: borderWidth),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    logoAsset,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.circle,
                      color: color,
                      size: size,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal rotating circle (SpinKit-like) used internally.
/// Mimics SpinKitRotatingCircle's alternating X/Y 3D tilt.
class _RotatingCircle extends StatefulWidget {
  const _RotatingCircle({
    required this.child,
    required this.duration,
    required this.size,
  });

  final Widget child;
  final Duration duration;
  final double size;

  @override
  State<_RotatingCircle> createState() => _RotatingCircleState();
}

class _RotatingCircleState extends State<_RotatingCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)..repeat();

  late final Animation<double> _animX = Tween(begin: 0.0, end: 180.0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ),
  );

  late final Animation<double> _animY = Tween(begin: 0.0, end: 180.0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: SizedBox.square(dimension: widget.size, child: widget.child),
      builder: (context, child) {
        final radX = -_animX.value * 0.0174533;
        final radY = -_animY.value * 0.0174533;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateX(radX)
            ..rotateY(radY),
          child: child,
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
