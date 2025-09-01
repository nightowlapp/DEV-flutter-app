import 'package:flutter/material.dart';
import 'package:nightowlcode/features/main/widgets/main_screen_left_drawer.dart';
import 'package:nightowlcode/features/main/widgets/main_screen_right_drawer.dart';

class MainScaffold extends StatelessWidget {
  final PreferredSizeWidget appBar;
  final Widget body;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;

  const MainScaffold({
    super.key,
    required this.appBar,
    required this.body,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar, // no fallback => no “sometimes wrong” app bar
      drawer: drawer ?? const MainScreenLeftDrawer(),
      endDrawer: endDrawer ?? const MainScreenRightDrawer(),
      endDrawerEnableOpenDragGesture: true,
      drawerEnableOpenDragGesture: true,
      bottomNavigationBar: bottomNavigationBar,
      body: body,
    );
  }
}
