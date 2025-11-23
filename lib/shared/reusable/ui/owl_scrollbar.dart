// lib/shared/reusable/ui/owl_scrollbar.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';

class OwlScrollbar extends StatelessWidget {
  const OwlScrollbar({
    super.key,
    required this.child,
    this.controller,
    this.thumbVisible = false,
    this.thickness = 4,
    this.radius = const Radius.circular(borderRadiusDefault),
    this.thumbColor,
  });

  final Widget child;
  final ScrollController? controller;
  final bool thumbVisible;
  final double thickness;
  final Radius radius;
  final Color? thumbColor;

  @override
  Widget build(BuildContext context) {
    final baseTheme = ScrollbarTheme.of(context);

    return ScrollbarTheme(
      data: baseTheme.copyWith(
        thumbColor: WidgetStateProperty.all(thumbColor ?? owlPurple),
      ),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: thumbVisible,
        thickness: thickness,
        radius: radius,
        child: child,
      ),
    );
  }
}
