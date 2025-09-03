import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

class PopupDialogDefault extends StatelessWidget {
  factory PopupDialogDefault({
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

    // NEW: alignment knobs
    TextAlign defaultTextAlign = TextAlign.start,
    CrossAxisAlignment bodyCrossAxisAlignment = CrossAxisAlignment.start,
    TextDirection? forceTextDirection, // pass TextDirection.ltr to force LTR
  }) {
    return PopupDialogDefault._internal(
      key: key,
      title: Utility.formatString(title),
      borderRadius: borderRadius,
      contentPadding: contentPadding,
      headerStyle: headerStyle ?? Styles.popupHeader,
      textStyle: textStyle ?? Styles.popupText,
      backgroundColor: backgroundColor ?? black,
      icon: icon ?? Image.asset('assets/nightowl/logo.png', width: 22, height: 22),
      showDivider: showDivider,
      divider: divider ?? const Divider(thickness: 0.3, color: owlOrange),
      border: border ?? Border.all(color: grey, width: 0.7),

      // pass-through
      defaultTextAlign: defaultTextAlign,
      bodyCrossAxisAlignment: bodyCrossAxisAlignment,
      forceTextDirection: forceTextDirection,
      children: children,
    );
  }

  const PopupDialogDefault._internal({
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

    // NEW:
    this.defaultTextAlign = TextAlign.start,
    this.bodyCrossAxisAlignment = CrossAxisAlignment.start,
    this.forceTextDirection,
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

  // NEW
  final TextAlign defaultTextAlign;
  final CrossAxisAlignment bodyCrossAxisAlignment;
  final TextDirection? forceTextDirection;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    Widget body = DefaultTextStyle(
      style: textStyle,
      textAlign: defaultTextAlign, // ⬅️ make all inherited Text left-aligned
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: bodyCrossAxisAlignment, // ⬅️ left-edge alignment
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: headerStyle,
                  textAlign: TextAlign.left, // explicit for header
                ),
              ),
              if (icon != null) icon!,
            ],
          ),
          if (showDivider) divider!,
          ...children,
        ],
      ),
    );

    // Optional: force LTR regardless of locale
    if (forceTextDirection != null) {
      body = Directionality(textDirection: forceTextDirection!, child: body);
    }

    return AlertDialog(
      backgroundColor: backgroundColor,
      insetPadding: EdgeInsets.only(bottom: screenHeight / 3),
      contentPadding: EdgeInsets.zero,
      content: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
        ),
        padding: contentPadding ?? const EdgeInsets.fromLTRB(20, 30, 20, 30),
        child: body,
      ),
    );
  }
}
