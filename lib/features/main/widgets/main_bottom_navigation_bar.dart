import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

class MainBottomNavigationBar extends StatelessWidget {
  final List<MainScreenName> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Number of unanswered friend requests shown on the Social tab.
  /// Hidden when 0 or null.
  final int? socialBadgeCount;

  const MainBottomNavigationBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.socialBadgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTabBar(
      backgroundColor: black,
      border: const Border(top: BorderSide(color: owlPurple, width: 0.04)),
      activeColor: owlPurple,
      inactiveColor: white,
      iconSize: iconSizeDefault,
      currentIndex: currentIndex,
      items: [
        for (final s in tabs)
          BottomNavigationBarItem(
            icon: _iconFor(s, isActive: false),
            activeIcon: _iconFor(s, isActive: true),
            label: s.label,
          ),
      ],
      onTap: onTap,
    );
  }

  Widget _iconFor(MainScreenName s, {required bool isActive}) {
    // Let IconTheme from CupertinoTabBar color the icon by keeping color = null,
    // except for admin where you want a fixed color.
    final base = Icon(
      s.icon,
      color: s == MainScreenName.admin ? adminColor : null,
    );

    if (s != MainScreenName.social) return base;

    final count = socialBadgeCount ?? 0;
    if (count <= 0) return base;

    final text = '${count > 9 ? '9+' : count}';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        base,
        Positioned(
          right: -8, // tweak offsets to taste
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Styles.mediumSmallText.copyWith(color: red, fontWeight: FontWeight.w900)
            ),
          ),
        ),
      ],
    );
  }
}
