import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nightowlcode/assets.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({
    super.key,
    this.imagePath = ImagePaths.logoColored,
    this.backgroundColor = transparent,
    this.imageSize = 150,
    this.slogan = 'Claim The Night',
    this.switchDuration = const Duration(seconds: 2),
    this.transitionDuration = const Duration(seconds: 1),
  });

  final String imagePath;
  final Color backgroundColor;
  final double imageSize;
  final String slogan;
  final Duration switchDuration;
  final Duration transitionDuration;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late final List<String> _logoPaths;
  final _random = Random();
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _logoPaths = <String>[
      ImagePaths.logoColored,
      // ImagePaths.logoUpBackground,
      // ImagePaths.logoRightBackground,
      // ImagePaths.logoDownBackground,
    ];

    // Start from the provided imagePath if it matches one of the logos
    final initialIndex = _logoPaths.indexOf(widget.imagePath);
    _currentIndex = initialIndex == -1 ? 0 : initialIndex;

    _timer = Timer.periodic(widget.switchDuration, (_) => _nextLogo());
  }

  void _nextLogo() {
    if (!mounted) return;

    int nextIndex = _currentIndex;
    if (_logoPaths.length > 1) {
      while (nextIndex == _currentIndex) {
        nextIndex = _random.nextInt(_logoPaths.length);
      }
    }

    setState(() {
      _currentIndex = nextIndex;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: widget.transitionDuration,
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 1.0,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: SizedBox(
                        key: ValueKey<String>(_logoPaths[_currentIndex]),
                        width: widget.imageSize,
                        height: widget.imageSize,
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(borderRadiusSmall),
                          child: Image.asset(
                            _logoPaths[_currentIndex],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      widget.slogan,
                      style: Styles.sloganStyle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
