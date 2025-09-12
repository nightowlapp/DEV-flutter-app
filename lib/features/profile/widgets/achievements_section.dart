import 'package:flutter/material.dart';
import 'package:nightowlcode/core/platform_config.dart';
import '../../../../shared/constants/styles.dart';
import '../../../../shared/constants/values.dart';

class AchievementsSection extends StatelessWidget {
  const AchievementsSection({
    super.key,
    required this.achieved,
    required this.total,
  });

  final int achieved;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Center(child: Text('My Achievements', style: Styles.basicText)),
            Align(
              alignment: Alignment.centerRight,
              child: Text('See All', style: Styles.basicText),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('$achieved/$total', style: Styles.basicText),
            ),
          ],
        ),
        const SizedBox(height: verticalSpacerSmall),
        SizedBox(
          height: PlatformConfig.height(context) * 0.2,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 8,
            separatorBuilder: (_, __) =>
                SizedBox(width: PlatformConfig.width(context) * 0.02),
            itemBuilder: (_, i) => const CircleAvatar(radius: iconSizeHuge),
          ),
        ),
      ],
    );
  }
}
