import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';

class Styles {
  static TextStyle get baseFont => GoogleFonts.bitter();
  // Cool fonts
  // static TextStyle get base => GoogleFonts.spaceGrotesk
  // static TextStyle get base => GoogleFonts.manrope
  // static TextStyle get base => GoogleFonts.figtree
  // static TextStyle get base => GoogleFonts.jetBrainsMono
  // static TextStyle get base => GoogleFonts.figtree();

  static TextStyle get fullNameDisplay => baseFont.copyWith(
      fontWeight: FontWeight.w600, color: white, fontSize: fontSizeLarge);

  static TextStyle get usernameDisplay => baseFont.copyWith(
      fontWeight: FontWeight.w600, color: white, fontSize: fontSizeMedium);

  static TextStyle get basicTextHeader => baseFont.copyWith(
      fontWeight: FontWeight.w600, color: white, fontSize: fontSizeMedium);

  static TextStyle get basicText => baseFont.copyWith(
      fontWeight: FontWeight.w200, color: white, fontSize: fontSizeSmall);

  static TextStyle get boldText =>
      baseFont.copyWith(fontWeight: FontWeight.w600, color: white);

  static TextStyle get h2Text => baseFont.copyWith(
      // fontSize: ,
      // fontWeight: FontWeight.w600,
      );

  static TextStyle get smallText => baseFont.copyWith(
        fontSize: fontSizeSmallest,
        color: white,
        // fontWeight: FontWeight.w600,
      );

  static TextStyle get mediumSmallText => baseFont.copyWith(
        fontSize: fontSizeSmaller,
        color: white,
        // fontWeight: FontWeight.w600,
      );

  static TextStyle get popupHeader => baseFont.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: fontSizeMedium,
      letterSpacing: 1.5);

  static TextStyle get popupText =>
      baseFont.copyWith(fontSize: fontSizeSmall, color: white);

  static TextStyle get greyedOutPopupText =>
      baseFont.copyWith(fontSize: fontSizeSmall, color: grey);

  static TextStyle get errorText =>
      baseFont.copyWith(color: red, fontWeight: FontWeight.w600);

  static TextStyle linkText(BuildContext context) => baseFont.copyWith(
      color: owlPurple,
      decoration: TextDecoration.underline,
      decorationColor: blue,
      decorationThickness: 1.6,
      decorationStyle: TextDecorationStyle.dashed,
      letterSpacing: 3.5);

  static TextStyle get sloganStyle => Styles.baseFont.copyWith(
        fontSize: fontSizeLarge,
        letterSpacing: 3,
        fontWeight: FontWeight.w800,
        foreground: Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              white,
              owlPurple,
              black,
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(
            const Rect.fromLTWH(60, 50, 300, 200),
          ),
      );
}
