import 'package:flutter/material.dart';
import '../../../../shared/constants/styles.dart';
import '../../../../shared/constants/values.dart';

class FriendsSectionRightDrawer extends StatefulWidget {
  const FriendsSectionRightDrawer({super.key});

  @override
  State<FriendsSectionRightDrawer> createState() => _FriendsSectionRightDrawerState();
}

class _FriendsSectionRightDrawerState extends State<FriendsSectionRightDrawer> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
    // const logoSize = logoIcon; //TODO

          children: [
            Center(child: Text('Friends', style: Styles.boldText)),
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
            itemCount: 20,
            separatorBuilder: (_, __) => const SizedBox(width: horizontalSpacerSmall),
            itemBuilder: (_, i) => const CircleAvatar(radius: circleAvatarSizeDefault),
          ),
        ),
      ],
    );
  }
}
