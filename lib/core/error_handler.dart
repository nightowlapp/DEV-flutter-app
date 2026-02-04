import 'package:flutter/material.dart';
import 'package:nightowlcode/core/app_exception.dart';
import 'package:nightowlcode/core/logger.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/data/repositories/users/feedback_repository.dart';

/// Attach this to MaterialApp.scaffoldMessengerKey
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

/// Call for any error you want to surface. Used by global handlers too.
void handleError(Object error, [StackTrace? stackTrace]) {
  final msg = error is AppException
      ? error.message
      : 'Something went wrong. Please try again.\n'
      'If something keeps going wrong you might want to check your app permissions under settings on your phone';

  // Log everything
  logE('Unhandled error', error, stackTrace);

  final messenger = scaffoldMessengerKey.currentState;
  if (messenger == null) return;

  final routeName = ModalRoute.of(messenger.context)?.settings.name;

  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: grey,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 10),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              msg,
              style: Styles.smallText,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Send error report',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            icon: const Icon(Icons.bug_report_outlined, color: owlPurple, size: 18),
            onPressed: () async {
              // Hide current snackbar so the user sees feedback quickly
              messenger.hideCurrentSnackBar();

              try {
                await FeedbackRepository.submitCrashReportGeneric(
                  error: error,
                  stackTrace: stackTrace,
                  route: routeName,
                  message: 'User tapped report button',
                );

                messenger.showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.green,
                    content: Text('Thanks! Report sent.'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (e, st) {
                logE('Failed to submit crash report', e, st);
                messenger.showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Could not send report (are you logged in?).'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}
