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
      fontWeight: FontWeight.w600,
      color: white,
    fontSize:fontSizeLarge
  );

  static TextStyle get usernameDisplay => baseFont.copyWith(
      fontWeight: FontWeight.w600,
      color: white,
      fontSize: fontSizeMedium
  );

  static TextStyle get basicTextHeader => baseFont.copyWith(
      fontWeight: FontWeight.w600,
      color: white,
      fontSize: fontSizeMedium
  );

  static TextStyle get basicText => baseFont.copyWith(
      fontWeight: FontWeight.w200,
      color: white,
      fontSize: fontSizeSmall
  );

  static TextStyle get boldText => baseFont.copyWith(
    fontWeight: FontWeight.w600,
    color: white
  );

  static TextStyle get h2Text => baseFont.copyWith(
  // fontSize: ,
  // fontWeight: FontWeight.w600,
  );

  static TextStyle get smallText => baseFont.copyWith(
    fontSize: 8,
    color: white,
    // fontWeight: FontWeight.w600,
  );

  static TextStyle get popupHeader => baseFont.copyWith(
    fontWeight: FontWeight.w600,
    fontSize: fontSizeMedium,
    letterSpacing: 1.5
  );

  static TextStyle get popupText => baseFont.copyWith(
    fontSize: fontSizeSmall,
    color: white
  );

  static TextStyle get greyedOutPopupText => baseFont.copyWith(
    fontSize: fontSizeSmall,
    color: grey
  );

  static TextStyle get errorText => baseFont.copyWith(
    color: red,
    fontWeight: FontWeight.w600
  );

  static TextStyle linkText(BuildContext context) => baseFont.copyWith(
    color: owlOrange,
    decoration: TextDecoration.underline,
    decorationColor: blue,
    decorationThickness: 1.6,
    decorationStyle: TextDecorationStyle.dashed,
    letterSpacing: 3.5
  );

  static TextStyle get logoTextGradient => baseFont.copyWith(
      letterSpacing: -1.4,
      fontSize: 26,
      fontWeight: FontWeight.w200,
      // foreground: Paint()
      //   ..shader = const LinearGradient(
      //       colors: [white, owlOrange, white],
      //   ).createShader(const Rect.fromLTWH(26, 50, 80, 33)),
    foreground: Paint() //TODO Cool font.
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = owlOrange,
  );



  static TextStyle get sloganTextGradient => baseFont.copyWith( //TODO
    fontSize: 20,
    letterSpacing: 3.5,
    fontWeight: FontWeight.w600,
    foreground: Paint()
      ..shader = const LinearGradient(
      colors: [owlOrange, white,white],
    ).createShader(const Rect.fromLTWH(26, 50, 80, 33)),
  );

  static Widget nameOrange() { final baseStyle = baseFont.copyWith(fontSize: 30, letterSpacing: -2.6, fontWeight: FontWeight.w200);
    return RichText(text: TextSpan(style: baseStyle, children: const[TextSpan(text: 'N', style: TextStyle(color: owlOrange, fontWeight: FontWeight.w500)), TextSpan(text: 'ight'), TextSpan(text: 'O', style: TextStyle(color: owlOrange, fontWeight: FontWeight.w500)), TextSpan(text: 'w', style: TextStyle(color: owlOrange, fontWeight: FontWeight.w500)), TextSpan(text: 'l')]));
  }


  static TextStyle get slogan => const TextStyle(
    fontSize: 33.0,
    fontWeight: FontWeight.w800,
    shadows: [
      Shadow(offset: Offset(-1, -1), blurRadius: 0, color: owlOrange),
      Shadow(offset: Offset(1, -1), blurRadius: 0, color: owlOrange),
      Shadow(offset: Offset(-1, 1), blurRadius: 0, color: owlOrange),
      Shadow(offset: Offset(2, 2), blurRadius: 0, color: owlOrange),
      Shadow(offset: Offset(0, -3), blurRadius: 0, color: owlOrange),
      Shadow(offset: Offset(0, 3), blurRadius: 0, color: owlOrange),
      Shadow(offset: Offset(-3, 0), blurRadius: 0, color: owlOrange),
      Shadow(offset: Offset(3, 0), blurRadius: 0, color: owlOrange),
    ],
  );

  static TextStyle get popShadowLogo => const TextStyle(
    fontSize: 33.0,
    fontWeight: FontWeight.w800,
    color: owlOrange,
    shadows: [
      Shadow(
        offset: Offset(2, 2),
        blurRadius: 0,
        color: black,
      ),
      Shadow(
        offset: Offset(-1, -1),
        blurRadius: 6,
        color: white,
      ),
    ],
  );






  static TextStyle get gradientLogo => TextStyle(
    fontSize: 33.0,
    fontWeight: FontWeight.w800,
    foreground: Paint()
      ..shader = const LinearGradient(
        colors: [black, owlOrange],
      ).createShader(const Rect.fromLTWH(0, 0, 300, 200)),
  );


  static Widget nameOrangeAttemptUpgrade() {
    final baseStyle = baseFont.copyWith(
      fontSize: 30,
      fontWeight: FontWeight.w200,
      letterSpacing: -2.6,
      // foreground: Paint(),

      shadows: const[
        Shadow(
          offset: Offset(0, 1),
          blurRadius: 2,
          color: Colors.black26
        )
      ]
    );

    TextStyle highlightStyle(Color color) {
      return baseStyle.copyWith(
        fontWeight: FontWeight.w600,
        foreground: Paint()
          ..shader = LinearGradient(
          colors: [color, white, color]
        ).createShader(const Rect.fromLTWH(30, 0, 80, 0))
      );
    }

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: 'N', style: highlightStyle(owlOrange)),
          const TextSpan(text: 'ight'),
          TextSpan(text: 'O', style: highlightStyle(owlOrange)),
          TextSpan(text: 'w', style: highlightStyle(owlOrange)),
          const TextSpan(text: 'l')
        ]
      )
    );
  }

  static Widget nameWhite() {
    final baseStyle = baseFont.copyWith(
      fontSize: 30,
      fontWeight: FontWeight.w200
    );
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: const[
          TextSpan(text: 'N', style: TextStyle(fontWeight: FontWeight.w500)),
          TextSpan(text: 'ight', style: TextStyle(color: owlOrange)),
          TextSpan(text: 'O', style: TextStyle(fontWeight: FontWeight.w500)),
          TextSpan(text: 'w', style: TextStyle(fontWeight: FontWeight.w500)),
          TextSpan(text: 'l', style: TextStyle(color: owlOrange))
        ]
      )
    );
  }









  static Widget logoCrazy(String text, {double fontSize = fontSizeSlogan}) {
    // Fill (multi-stop orange gradient)
    final TextStyle fill = GoogleFonts.pacifico( // cursive/script look
      fontSize: fontSize,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w100,
      letterSpacing: 2, // make it feel wide
      height: 1,
      shadows: [
        Shadow( // soft outer glow for POP
          color: owlOrange.withOpacity(0.70),
          offset: const Offset(0, 0),
          blurRadius: 6,
        ),
        const Shadow(
          color: white,
          offset: Offset(0, 1),
          blurRadius: 1,
        ),
      ],
    ).copyWith(
      foreground: Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-1.0, -0.8),
          end: Alignment(1.0, 0.8),
          colors: <Color>[
            white,
            white,
            owlOrange,         // brand orange
            owlOrange,         // brand orange
            white,
            owlOrange,
white          ],
        ).createShader(Rect.fromLTWH(0, 0, fontSize * 10, fontSize * 2)), // wide gradient span
    );

    // Stroke/outline to separate from dark backgrounds
    final TextStyle stroke = GoogleFonts.pacifico(
      fontSize: fontSize,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
      height: 1,
    ).copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = fontSize * 0.1
        ..color = white.withOpacity(0.3),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(text, style: stroke),
        Text(text, style: fill),
      ],
    );
  }




/// test1 — left-to-right warm hint like the sample (subtle orange leading edge)
static TextStyle get test1 => baseFont.copyWith(
  fontSize: fontSizeLarge,
  foreground: Paint()
    ..shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [owlOrange, white, white],
      stops: [0.0, 0.45, 1.0],
    ).createShader(const Rect.fromLTWH(0, 0, 240, 48)),
);

/// test2 — stronger orange → gold → white sweep (slightly more saturated)
static TextStyle get test2 => baseFont.copyWith(
  fontSize: fontSizeLarge,

  letterSpacing: 0.8,
  foreground: Paint()
    ..shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [owlOrange, owlGold, white],
      stops: [0.0, 0.35, 1.0],
    ).createShader(const Rect.fromLTWH(0, 0, 240, 48)),
);

/// test3 — top-to-bottom soft warmth at the baseline (gives a gilded lower edge)
static TextStyle get test3 => baseFont.copyWith(
  fontSize: fontSizeLarge,
  foreground: Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [white, white, owlAmber],
      stops: [0.0, 0.65, 1.0],
    ).createShader(const Rect.fromLTWH(0, 0, 220, 56)),
);

/// test4 — center highlight (white → gold → white) for a glossy mid-band
static TextStyle get test4 => baseFont.copyWith(
  fontSize: fontSizeLarge,
  foreground: Paint()
    ..shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [white, owlGold, white],
      stops: [0.15, 0.5, 0.85],
    ).createShader(const Rect.fromLTWH(0, 0, 260, 52)),
);

/// test5 — gentle amber kiss near the “Owl” end (bias warmth to the right)
static TextStyle get test5 => baseFont.copyWith(
  fontSize: fontSizeLarge,
  letterSpacing: 0.7,
  foreground: Paint()
    ..shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [white, white, owlAmber],
      stops: [0.0, 0.7, 1.0],
    ).createShader(const Rect.fromLTWH(0, 0, 260, 50)),
);



  static const Color owlAmber  = Color(0xFFF2B36D);
  static const Color owlGold   = Color(0xFFFFD186);


}
