// lib/shared/widgets/owl_snack.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/utility/utility.dart';
import 'package:nightowlcode/assets.dart';

enum OwlSnackVariant { info, success, warning, error, neutral }

class OwlSnack {
  /// Show a floating bottom snackbar with title + optional message.
  /// Requires a [ScaffoldMessenger] in the widget tree.
  static void show(
    // TODO bool to push forward on screen z value.
    BuildContext context, {
    required String title,
    String? message,
    OwlSnackVariant variant = OwlSnackVariant.neutral,
    SnackBarBehavior behavior = SnackBarBehavior.floating, // <- rename
    // Visuals
    Widget? icon,
    bool showIcon = true,
    double iconSize = 22,
    bool showDivider = true,
    Duration duration = const Duration(seconds: 3),
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double borderRadius = borderRadiusDefault,
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final palette = _paletteFor(variant);
    final bg = backgroundColor ?? palette.$1;
    final fg = textColor ?? palette.$2;
    final brd = borderColor ?? palette.$3;

    final Widget defaultIcon = Image.asset(
      ImagePaths.logo,
      width: iconSize,
      height: iconSize,
    );
    final Widget iconWidget = icon ?? defaultIcon;

    final content = DefaultTextStyle(
      style: Styles.popupText.copyWith(color: fg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  Utility.formatString(title),
                  style: Styles.mediumSmallText.copyWith(color: fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showIcon)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: iconWidget,
                ),
            ],
          ),
          if (showDivider) const Divider(color: owlPurple),
          if ((message ?? '').trim().isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message!,
                style: Styles.popupText.copyWith(color: fg),
              ),
            ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: fg,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onAction();
                },
                child: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );

    final snack = SnackBar(
      behavior: behavior, // <- use the param here
      duration: duration,
      margin: margin ?? const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: padding ?? const EdgeInsets.fromLTRB(16, 14, 16, 14),
      elevation: 0,
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: brd, width: 0.7),
      ),
      content: content,
    );

    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(snack);
  }

  /// Default palette per variant: (background, text, border).
  static (Color, Color, Color) _paletteFor(OwlSnackVariant v) {
    switch (v) {
      case OwlSnackVariant.success:
        return (
          const Color(0xFF0F3E2C),
          const Color(0xFFB6F6D6),
          const Color(0xFF2DD389)
        );
      case OwlSnackVariant.warning:
        return (
          const Color(0xFF3E2F0F),
          const Color(0xFFFFE6B3),
          const Color(0xFFFFC14A)
        );
      case OwlSnackVariant.error:
        return (
          const Color(0xFF3E1414),
          const Color(0xFFFFC7C7),
          const Color(0xFFFF6B6B)
        );
      case OwlSnackVariant.info:
        return (
          const Color(0xFF14253E),
          const Color(0xFFBFD9FF),
          const Color(0xFF5AA8FF)
        );
      case OwlSnackVariant.neutral:
      default:
        return (black, white, grey);
    }
  }
}
