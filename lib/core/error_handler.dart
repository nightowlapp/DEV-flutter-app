import 'package:flutter/material.dart';
import 'package:nightowlcode/core/app_exception.dart';
import 'package:nightowlcode/core/logger.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

import '../shared/constants/styles.dart';

/// Attach this to MaterialApp.scaffoldMessengerKey
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Call for any error you want to surface. Used by global handlers too.
void handleError(Object error, [StackTrace? stackTrace]) {
  // If it's your AppException, show its message; otherwise show a generic one.
  final msg = error is AppException
      //TODO If in production do somehting else.
      ? error.message
      : 'Something went wrong. Please try again.\nIf something keeps going wrong you might want to check your app permissions under settings on your phone';

  // Log everything (replace with Crashlytics later if you want)
  logE('Unhandled error', error, stackTrace);

  // Surface a simple user-facing message
  final messenger = scaffoldMessengerKey.currentState;
  if (messenger != null) {
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text(
        msg,
        style: Styles.smallText,
      ),
      backgroundColor: grey,
    ));
  }
}
