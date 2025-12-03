import 'package:flutter/material.dart';
import 'package:nightowlcode/core/platform_config.dart';
import '../../../../shared/constants/styles.dart';
import '../../../../shared/constants/values.dart';
import '../../../shared/constants/colors.dart';

class EmblemsSection extends StatelessWidget {
  const EmblemsSection({
    super.key,
    required this.title,
    required this.achieved,
    required this.total,
  });

  final int achieved;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Center(child: Text(title, style: Styles.basicText)),
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: Text('See All', style: Styles.basicText),
            // ),
            // Align(
            //   alignment: Alignment.centerLeft,
            //   child: Text('$achieved/$total', style: Styles.basicText),
            // ),
          ],
        ),
        const SizedBox(height: verticalSpacerSmall),
        SizedBox(
          height: PlatformConfig.height(context) * 0.2,
          child: Center(
              child: Text(
            "Coming soon",
            style: Styles.basicText.copyWith(color: orange),
          )),
          // child: ListView.separated(
          //   scrollDirection: Axis.horizontal,
          //   itemCount: 8,
          //   separatorBuilder: (_, __) =>
          //       SizedBox(width: PlatformConfig.width(context) * 0.02),
          //   itemBuilder: (_, i) => const CircleAvatar(radius: iconSizeHuge),
          // ),
        ),
      ],
    );
  }
}
