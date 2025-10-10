import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';

class AppTheme {
  final ThemeData defaultAppTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: black,
    colorScheme: ColorScheme.fromSeed(
      seedColor: owlPurple,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    textTheme: GoogleFonts.bitterTextTheme()
        .copyWith(
          bodySmall:
              GoogleFonts.bitter(fontSize: fontSizeSmallest, color: white),
          bodyMedium: GoogleFonts.bitter(fontSize: fontSizeSmall, color: white),
          bodyLarge: GoogleFonts.bitter(fontSize: fontSizeMedium, color: white),

// Todo all of these variants:
// displayLarge: ,
// headlineLarge: ,
// titleLarge: ,
//         labelSmall:
        )
        .apply(
          bodyColor: white,
          displayColor: white,
        ),
  );
}
