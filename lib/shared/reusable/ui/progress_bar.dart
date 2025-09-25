import 'package:flutter/material.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';

class ProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final double marginHorizontal;

  const ProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.marginHorizontal = 20,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // Prevents user interaction with the progress bar
      child: Column(children: [
      Center(child: Text('$currentStep of $totalSteps', style: Styles.boldText,)),Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(totalSteps, (index) {
          bool isCompleted = index < currentStep - 1;
          bool isActive = index == currentStep - 1;

          return Expanded(
            child:
              Container(
              margin: EdgeInsets.symmetric(
                  horizontal: marginHorizontal, vertical: PlatformConfig.height(context) *0.05),
              height: 5, // Adjust thickness if needed
              decoration: BoxDecoration(
                color: isCompleted
                    ? owlPurple // Completed
                    : isActive
                    ? greyLighter // Active
                    : grey, // Inactive
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }),
      ),])
    );
  }
}
