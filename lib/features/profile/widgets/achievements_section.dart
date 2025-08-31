import 'package:flutter/material.dart';
import '../../../../shared/constants/styles.dart';
import '../../../../shared/constants/values.dart';

class AchievementsSection extends StatefulWidget {
  const AchievementsSection({super.key});

  @override
  State<AchievementsSection> createState() => _AchievementsSectionState();
}

class _AchievementsSectionState extends State<AchievementsSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Center(child: Text('My Achievements', style: Styles.basicTextHeader)),
            Align(
              alignment: Alignment.centerRight,
              child: Text("See All",style: Styles.basicTextHeader),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("37/136",style: Styles.basicTextHeader),
            ),
          ],
        ),
        const SizedBox(height: verticalSpacerSmall),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 8,
            separatorBuilder: (_, __) => const SizedBox.shrink(),
            itemBuilder: (_, i) => const CircleAvatar(radius: iconSizeLarge),
          ),
        ),
      ],
    );
  }
}
