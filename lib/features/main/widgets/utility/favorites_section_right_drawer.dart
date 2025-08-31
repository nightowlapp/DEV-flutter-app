import 'package:flutter/material.dart';
import '../../../../shared/constants/styles.dart';
import '../../../../shared/constants/values.dart';

class FavoritesSectionRightDrawer extends StatefulWidget {
  const FavoritesSectionRightDrawer({super.key});

  @override
  State<FavoritesSectionRightDrawer> createState() => _FavoritesSectionRightDrawerState();
}

class _FavoritesSectionRightDrawerState extends State<FavoritesSectionRightDrawer> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Center(child: Text('Favorites', style: Styles.boldText)),
            const Align(
              alignment: Alignment.centerRight,
              child: Text("1/2"),
            ),
          ],
        ),
        const SizedBox(height: verticalSpacerSmall),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 8,
            separatorBuilder: (_, __) => const SizedBox(width: horizontalSpacerSmall),
            itemBuilder: (_, i) => const CircleAvatar(radius: circleAvatarSizeDefault),
          ),
        ),
      ],
    );
  }
}
