// lib/shared/reusable/sign_up_or_login/sign_up.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/core/platform_config.dart';
import '../ui/progress_bar.dart';

class SignUp extends StatelessWidget {
  final List<Widget> formFields;
  final Widget? bottomContent;
  final bool showProgressBar;
  final int currentStep;
  final int totalSteps;

  /// When embedding inside an existing page (that already has a Scaffold),
  /// set [useScaffold] to false to avoid nested Scaffold overflow.
  final bool useScaffold;

  const SignUp({
    super.key,
    required this.formFields,
    this.bottomContent,
    this.showProgressBar = true,
    this.currentStep = 1,
    this.totalSteps = 3,
    this.useScaffold = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Stack(
        children: [
          // Scrollable form content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 0,
                right: 0,
                top: PlatformConfig.height(context) * 0.02,
                // leave space so content isn't hidden behind bottom progress bar
                bottom: 72,
              ),
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...formFields,
                    if (bottomContent != null) ...[
                      const SizedBox(height: 24),
                      bottomContent!,
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Bottom progress bar (safe)
          if (showProgressBar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: ProgressBar(
                  currentStep: currentStep,
                  totalSteps: totalSteps,
                  // match your original compact style when < 3 steps
                  marginHorizontal: totalSteps < 3 ? 20 : 10,
                ),
              ),
            ),
        ],
      ),
    );

    if (useScaffold) {
      return Scaffold(body: content);
    }
    return content;
  }
}
