// lib/shared/ui/owl_dialogs.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

class OwlDialogs {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool dismissible = false,
    Color barrier = transparent, // TODO find greyd out color.
    bool useRootNavigator = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: barrier,
      useRootNavigator: useRootNavigator,
      builder: (_) => child,
    );
  }
}
