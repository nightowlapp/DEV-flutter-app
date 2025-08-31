import 'dart:io';
import 'package:flutter/material.dart';

class PlatformConfig {
  // PLATFORM CHECKS
  static final bool isIOS = Platform.isIOS;
  static final bool isAndroid = Platform.isAndroid;

  // static final bool isMacOS = Platform.isMacOS;
  // static final bool isWindows = Platform.isWindows;
  // static final bool isLinux = Platform.isLinux;

  // DEVICE DIMENSIONS
  /// Returns device screen width in logical pixels.
  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Returns device screen height in logical pixels.
  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Returns device aspect ratio (width / height).
  static double aspectRatio(BuildContext context) =>
      MediaQuery.of(context).size.aspectRatio;

  /// Returns device pixel ratio (for scaling assets).
  static double pixelRatio(BuildContext context) =>
      MediaQuery.of(context).devicePixelRatio;

  // DEVICE TYPE
  /// Returns true if device is considered a phone.
  static bool isPhone(BuildContext context) => width(context) < 600;

  /// Returns true if device is considered a tablet.
  static bool isTablet(BuildContext context) =>
      width(context) >= 600 && width(context) < 1024;

  /// Returns true if device is considered a desktop.
  static bool isDesktop(BuildContext context) => width(context) >= 1024;

  // ORIENTATION
  /// Returns current device orientation.
  static Orientation orientation(BuildContext context) =>
      MediaQuery.of(context).orientation;

  /// Returns true if device is in portrait mode.
  static bool isPortrait(BuildContext context) =>
      orientation(context) == Orientation.portrait;

  /// Returns true if device is in landscape mode.
  static bool isLandscape(BuildContext context) =>
      orientation(context) == Orientation.landscape;

  // SAFE AREA / PADDING
  /// Top system inset (e.g., notch or status bar).
  static double topInset(BuildContext context) =>
      MediaQuery.of(context).padding.top;

  /// Bottom system inset (e.g., home indicator).
  static double bottomInset(BuildContext context) =>
      MediaQuery.of(context).padding.bottom;

  /// Left system inset (e.g., for foldables).
  static double leftInset(BuildContext context) =>
      MediaQuery.of(context).padding.left;

  /// Right system inset (e.g., for foldables).
  static double rightInset(BuildContext context) =>
      MediaQuery.of(context).padding.right;

  // TEXT & ACCESSIBILITY
  /// User's preferred text scaling factor.
  static double textScale(BuildContext context) =>
      MediaQuery.of(context).textScaleFactor;

  /// True if user has requested bold/large accessibility text.
  static bool isLargeText(BuildContext context, {double threshold = 1.2}) =>
      textScale(context) >= threshold;

  // --------------------
  // PLATFORM BRIDGE
  // --------------------
  /// Returns the current platform as a string.
  static String platformName() {
    if (isIOS) return "ios";
    if (isAndroid) return "android";
    // if (isMacOS) return "macOS";
    // if (isWindows) return "Windows";
    // if (isLinux) return "Linux";
    // if (isFuchsia) return "Fuchsia";
    return "Unknown";
  }
}
