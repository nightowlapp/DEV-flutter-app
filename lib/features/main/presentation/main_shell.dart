import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:nightowlcode/features/main/widgets/main_bottom_navigation_bar.dart';
import 'package:nightowlcode/features/main/widgets/main_app_bar.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import '../../../data/services/notifications/segment_service.dart';
import '../../../navigation/router.dart';
import 'main_scaffold.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell nav;
  final bool isAdmin;
  final bool isOwner;

  const MainShell({
    super.key,
    required this.nav,
    this.isAdmin = false, // TODO Real update
    this.isOwner = false,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _prewarmed = false;
  String? _token;
  List<String> _appliedTopics = [];


  @override
  void initState() {
    super.initState();
    // SchedulerBinding.instance.addPostFrameCallback((_) => _prewarmMapBranchSafely());
    _load();
    FirebaseMessaging.onMessage.listen((message) { // TODO Want to seperate notifications in one folder.
      // You could surface a local notification here if you want a foreground banner
      // For now we keep it simple
      final snack = SnackBar(
        content: Text('Push received: ${message.notification?.title ?? ''}'),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snack);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // Handle deep link via message.data if needed
    });
  }

  Future<void> _load() async {
    final token = await FirebaseMessaging.instance.getToken();
    final topics = await SegmentService().applySubscriptions();
    setState(() {
      _token = token;
      _appliedTopics = topics;
    });
  }

  // Future<void> _prewarmMapBranchSafely() async { // TODO Make map start without going there.
  //   if (_prewarmed) return;
  //   _prewarmed = true;
  //
  //   await SchedulerBinding.instance.endOfFrame;
  //   await Future.delayed(const Duration(milliseconds: 1));
  //   if (!mounted) return;
  //
  //   final tabs = _visibleTabs();
  //   if (!tabs.contains(MainScreenName.map)) return;
  //
  //   final original = widget.nav.currentIndex;
  //
  //   if (mapIndexGlobal == -1 || mapIndexGlobal == original) return;
  //
  //   try {
  //     widget.nav.goBranch(mapIndexGlobal, initialLocation: true);
  //     await SchedulerBinding.instance.endOfFrame;
  //   } catch (_) {}
  //
  //   if (!mounted) return;
  //   try {
  //     widget.nav.goBranch(original, initialLocation: false);
  //   } catch (_) {}
  // }

  List<MainScreenName> _visibleTabs() {
    // start from canonical order, then filter
    return kBranchOrder.where((s) {
      if (!s.showNav) return false;
      if (s == MainScreenName.admin && !widget.isAdmin) return false;
      if (s == MainScreenName.venues && !widget.isOwner) return false;
      return true;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _visibleTabs();

    // the active root comes from the shell's branch index in kBranchOrder
    final MainScreenName activeGlobal = kBranchOrder[widget.nav.currentIndex];

    // map to visible index for the bottom bar (no values[]!)
    final currentVisibleIndex = tabs.indexOf(activeGlobal).clamp(0, tabs.length - 1);

    return MainScaffold(
      appBar: MainAppBar(),
      body: SafeArea(child: widget.nav),
      bottomNavigationBar: MainBottomNavigationBar(
        tabs: tabs,
        currentIndex: currentVisibleIndex,
        onTap: (i) {
          final target = tabs[i];
          final branchIndex = kBranchOrder.indexOf(target); // <- map enum → branch
          widget.nav.goBranch(
            branchIndex,
            initialLocation: branchIndex == widget.nav.currentIndex,
          );
        },
      ),
    );
  }

// Also fix the prewarm to use kBranchOrder
  Future<void> _prewarmMapBranchSafely() async {
    if (_prewarmed) return;
    _prewarmed = true;

    await SchedulerBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 1));
    if (!mounted) return;

    final tabs = _visibleTabs();
    if (!tabs.contains(MainScreenName.map)) return;

    final mapIndexGlobal = kBranchOrder.indexOf(MainScreenName.map); // <-- here
    final original = widget.nav.currentIndex;

    if (mapIndexGlobal == -1 || mapIndexGlobal == original) return;

    try {
      widget.nav.goBranch(mapIndexGlobal, initialLocation: true);
      await SchedulerBinding.instance.endOfFrame;
    } catch (_) {}

    if (!mounted) return;
    try {
      widget.nav.goBranch(original, initialLocation: false);
    } catch (_) {}
  }
}
