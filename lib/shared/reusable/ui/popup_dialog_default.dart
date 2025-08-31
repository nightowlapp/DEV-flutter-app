import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';

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
  }) {
    return PopupDialogDefault._internal(
      key: key,
      title: title,
      borderRadius: borderRadius,
      contentPadding: contentPadding,
      headerStyle: headerStyle ?? Styles.popupHeader,
      textStyle: textStyle ?? Styles.popupText,
      backgroundColor: backgroundColor ?? black,
      icon: icon ?? Image.asset('assets/nightowl/logo.png', width: 22, height: 22),
      showDivider: showDivider,
      divider: divider ?? const Divider(
        thickness: 0.3,
        color: owlOrange,
      ),
      border: border ??Border.all(color: grey, width: 0.7),
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AlertDialog(
      backgroundColor: backgroundColor,
      insetPadding: EdgeInsets.only(bottom: screenHeight * 1 / 3),
      contentPadding: EdgeInsets.zero,
      content: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
        ),
        padding: contentPadding ?? const EdgeInsets.fromLTRB(20, 30, 20, 30),
        child: DefaultTextStyle(
          style: textStyle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(title, style: headerStyle, textAlign: TextAlign.left),
                  ),
                  if (icon != null) icon!,
                ],
              ),
              if (showDivider) divider!,
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
