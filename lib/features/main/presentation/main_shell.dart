import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightowlcode/features/main/widgets/main_bottom_navigation_bar.dart';
import 'package:nightowlcode/features/main/widgets/main_app_bar.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import '../../../data/providers/users/friends/friend_request_provider.dart';
import '../../../data/repositories/users/role_repository.dart';
import '../../../data/services/notifications/segment_service.dart';
import '../../../navigation/router.dart';
import 'main_scaffold.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell nav;

  const MainShell({
    super.key,
    required this.nav,
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
    _load();
  }

  Future<void> _load() async {
    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (_) {
      // Swallow APNS token errors so app can run on iOS sim
      token = null;
    }
    final topics = await SegmentService().applySubscriptions();
    setState(() {
      _token = token;
      _appliedTopics = topics;
    }
    );
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


  List<MainScreenName> _visibleTabs(UserRoles roles) {
    return kBranchOrder.where((s) {
      if (!s.showNav) return false;
      if (s == MainScreenName.admin && !roles.isAdmin) return false;
      if (s == MainScreenName.venues && !(roles.isOwner || roles.isAdmin)) return false;
      return true;
    }).toList(growable: false);
  }


  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final rolesAsync = ref.watch(userRolesProvider);

        return rolesAsync.when(
          data: (roles) {
            final tabs = _visibleTabs(roles);

            final MainScreenName activeGlobal = kBranchOrder[widget.nav
                .currentIndex];
            final currentVisibleIndex = tabs.indexOf(activeGlobal).clamp(
                0, tabs.length - 1);

            return MainScaffold(
              appBar: MainAppBar(screen: activeGlobal),
              body: widget.nav,
              bottomNavigationBar: Consumer(
                builder: (context, ref, _) {
                  final pendingCount = ref.watch(pendingRequestsCountProvider);
                  return MainBottomNavigationBar(
                    tabs: tabs,
                    currentIndex: currentVisibleIndex,
                    onTap: (i) {
                      final target = tabs[i];
                      final branchIndex = kBranchOrder.indexOf(target);
                      widget.nav.goBranch(  
                          branchIndex, initialLocation: branchIndex ==
                          widget.nav.currentIndex);
                    },
                    socialBadgeCount: pendingCount,
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Failed to load roles')),
        );
      },
    );
  }
}
