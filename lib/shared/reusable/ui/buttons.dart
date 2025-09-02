// lib/shared/reusable/ui/buttons.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';

/// A dead-simple, always-available button with **three** customizable colors.
/// Everything has sensible defaults.
///
/// Customize only what you need:
///   OwlButton(
///     label: 'Continue',
///     onPressed: () {},
///     backgroundColor: Colors.teal,   // optional
///     textColor: Colors.white,         // optional
///     borderColor: Colors.transparent, // optional
///     icon: Icons.google,              // optional (defaults to none)
///   )
// class OwlButton extends StatelessWidget {
//   const OwlButton({
//     super.key,
//     required this.label,
//     required this.onPressed,
//     this.backgroundColor,
//     this.textColor,
//     this.borderColor,
//     this.fullWidth = true,
//     this.borderRadius = borderRadiusMedium,
//     this.padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
//     this.icon,
//     this.iconSize = iconSizeDefault,
//     this.iconPadding = const EdgeInsets.only(left: horizontalSpacerDefault),
//   });
//
//   final String label;
//   final VoidCallback? onPressed;
//
//   /// Customizable colors (all optional). If not provided, defaults apply.
//   final Color? backgroundColor;
//   final Color? textColor;
//   final Color? borderColor;
//
//   /// Minor layout knobs
//   final bool fullWidth;
//   final double borderRadius;
//   final EdgeInsetsGeometry padding;
//
//   /// Optional left icon. Default: none.
//   final IconData? icon;
//   final double iconSize;
//   final EdgeInsets iconPadding;
//
//   @override
//   Widget build(BuildContext context) {
//     final Color bg = backgroundColor ?? transparent;
//     final Color fg = textColor ?? (bg == transparent ? owlOrange : white);
//     final Color sideColor = borderColor ?? white;
//
//     // Reserve equal space on left & right so text stays visually centered even with a left icon.
//     final double iconArea = icon == null ? 0 : (iconSize + iconPadding.horizontal);
//
//     final button = ElevatedButton(
//       onPressed: onPressed,
//       style: ElevatedButton.styleFrom(
//         elevation: 0,
//         backgroundColor: bg,
//         foregroundColor: fg,
//         padding: padding,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(borderRadius),
//           side: BorderSide(color: sideColor, width: sideColor == transparent ? 0 : 2),
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Left icon area
//           SizedBox(
//             width: iconArea,
//             child: icon == null
//                 ? const SizedBox.shrink()
//                 : Padding(
//               padding: iconPadding,
//               child: Icon(icon, size: iconSize, color: fg),
//             ),
//           ),
//
//           // Centered text
//           Expanded(
//             child: Center(
//               child: Text(
//                 label,
//                 maxLines: 1,
//                 style: TextStyle(
//                   color: fg,
//                   fontWeight: FontWeight.w600,
//                   fontSize: fontSizeMedium,
//                   letterSpacing: 0,
//                 ),
//               ),
//             ),
//           ),
//
//           // Right spacer to balance the left icon area
//           SizedBox(width: iconArea),
//         ],
//       ),
//     );
//
//     return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
//   }
// }


class OwlButton extends StatelessWidget {
  const OwlButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.fullWidth = true,
    this.borderRadius = borderRadiusMedium,
    this.padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    this.icon,
    this.iconSize = iconSizeDefault,
    this.iconPadding = const EdgeInsets.only(left: horizontalSpacerDefault),
  });

  final String label;
  final VoidCallback? onPressed;

  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  final bool fullWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  final IconData? icon;
  final double iconSize;
  final EdgeInsets iconPadding;

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? transparent;
    final Color fg = textColor ?? (bg == transparent ? owlOrange : white);
    final Color sideColor = borderColor ?? white;

    final double iconArea = icon == null ? 0 : (iconSize + iconPadding.horizontal);

    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: fg,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: sideColor, width: sideColor == transparent ? 0 : 2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // left icon area
          SizedBox(
            width: iconArea,
            child: icon == null
                ? const SizedBox.shrink()
                : Padding(
              padding: iconPadding,
              child: Icon(icon, size: iconSize, color: fg),
            ),
          ),
          // centered text (no Expanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: fontSizeMedium,
                letterSpacing: 0,
              ),
            ),
          ),
          // right spacer same as left to keep text visually centered
          SizedBox(width: iconArea),
        ],
      ),
    );

    // NOTE: when placing inside a Row, set fullWidth: false or wrap with Expanded.
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
