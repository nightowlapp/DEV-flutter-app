import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/utility/utility.dart';
import 'package:nightowlcode/assets.dart';

class OwlPopup extends StatelessWidget {
  factory OwlPopup({
    Key? key,
    required String title,
    required List<Widget> children,
    double borderRadius = borderRadiusDefault,
    EdgeInsetsGeometry? contentPadding,
    TextStyle? headerStyle,
    TextStyle? textStyle,
    Color? backgroundColor,
    Widget? icon,
    Widget? divider,
    bool showDivider = true,
    Border? border,

    // alignment knobs
    TextAlign defaultTextAlign = TextAlign.start,
    CrossAxisAlignment bodyCrossAxisAlignment = CrossAxisAlignment.start,
    TextDirection? forceTextDirection,

    // NEW: size knobs
    double maxHeightFraction = 0.85, // cap dialog height to 85% of screen
    double maxWidth = 560, // optional desktop/tablet nicety
  }) {
    return OwlPopup._internal(
      key: key,
      title: Utility.formatString(title),
      borderRadius: borderRadius,
      contentPadding: contentPadding,
      headerStyle: headerStyle ?? Styles.popupHeader,
      textStyle: textStyle ?? Styles.popupText,
      backgroundColor: backgroundColor ?? black,
      icon: icon ?? Image.asset(ImagePaths.logoColored, width: 22, height: 22),
      showDivider: showDivider,
      divider: divider ?? const Divider(thickness: 0.3, color: owlPurple),
      border: border ?? Border.all(color: grey, width: 0.7),

      defaultTextAlign: defaultTextAlign,
      bodyCrossAxisAlignment: bodyCrossAxisAlignment,
      forceTextDirection: forceTextDirection,

      // size
      maxHeightFraction: maxHeightFraction,
      maxWidth: maxWidth,
      children: children,
    );
  }

  const OwlPopup._internal({
    super.key,
    required this.title,
    required this.children,
    required this.headerStyle,
    required this.textStyle,
    this.borderRadius = borderRadiusDefault,
    this.contentPadding,
    this.backgroundColor,
    this.icon,
    this.divider,
    this.showDivider = true,
    this.border,
    this.defaultTextAlign = TextAlign.start,
    this.bodyCrossAxisAlignment = CrossAxisAlignment.start,
    this.forceTextDirection,
    this.maxHeightFraction = 0.85,
    this.maxWidth = 560,
  });

  final String title;
  final List<Widget> children;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle headerStyle;
  final TextStyle textStyle;
  final Color? backgroundColor;
  final Widget? icon;
  final Widget? divider;
  final bool showDivider;
  final Border? border;

  final TextAlign defaultTextAlign;
  final CrossAxisAlignment bodyCrossAxisAlignment;
  final TextDirection? forceTextDirection;

  final double maxHeightFraction;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets; // keyboard
    // Respect keyboard by reducing the available height
    final availableHeight = (size.height - viewInsets.bottom).clamp(0.0, size.height);
    final maxH = (availableHeight * maxHeightFraction)
        .clamp(240.0, availableHeight);

    Widget body = DefaultTextStyle(
      style: textStyle,
      textAlign: defaultTextAlign,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: bodyCrossAxisAlignment,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child:
                    Text(title, style: headerStyle, textAlign: TextAlign.left),
              ),
              if (icon != null) icon!,
            ],
          ),
          if (showDivider) divider!,
          ...children,
        ],
      ),
    );

    if (forceTextDirection != null) {
      body = Directionality(textDirection: forceTextDirection!, child: body);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.decelerate,
          // Only pad by keyboard on the bottom to avoid over-shifting
          padding: EdgeInsets.only(bottom: viewInsets.bottom) +
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: AlertDialog(
            backgroundColor: backgroundColor,
            clipBehavior: Clip.antiAlias,
            contentPadding: EdgeInsets.zero,
            insetPadding: EdgeInsets.zero, // already handled by AnimatedPadding
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxH,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.zero,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: border,
                  ),
                  padding: contentPadding ??
                      const EdgeInsets.fromLTRB(20, 30, 20, 30),
                  child: body,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
