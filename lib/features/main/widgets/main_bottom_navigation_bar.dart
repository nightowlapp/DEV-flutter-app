// lib/features/main/widgets/main_bottom_navigation_bar.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
class MainBottomNavigationBar extends StatelessWidget {
  final List<MainScreenName> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNavigationBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTabBar(
      backgroundColor: black,
      border: const Border(top: BorderSide(color: owlOrange, width: 0.04)),
      activeColor: owlOrange,
      inactiveColor: white,
      iconSize: iconSizeDefault,
      currentIndex: currentIndex,
      items: [
        for (final s in tabs)
          BottomNavigationBarItem(
            icon: Icon(s.icon, color: s == MainScreenName.admin ? adminColor : null),
            label: s.label,
          ),
      ],
      onTap: onTap,
    );
  }
}
