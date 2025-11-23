// lib/features/main/presentation/main_shell.dart
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nightowlcode/data/providers/favorite_venues/favorites_providers.dart';
import 'package:nightowlcode/features/main/widgets/main_bottom_navigation_bar.dart';
import 'package:nightowlcode/features/main/widgets/main_app_bar.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/reusable/ui/loading/error_screen.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_screen.dart';

import '../../../data/providers/users/friends/friend_request_provider.dart';
import '../../../data/repositories/users/role_repository.dart';
import '../../../data/services/notifications/notification_service.dart';
import '../../../data/services/notifications/segment_service.dart';
import '../../../navigation/router.dart';
import 'main_scaffold.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell nav;

  const MainShell({super.key, required this.nav});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _prewarmed = false;
  String? _token;
  List<String> _appliedTopics = [];
  bool _notifInitStarted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    String? token;
    List<String> topics = const [];

    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (_) {
      // Swallow APNS token errors so app can run on iOS sim
      token = null;
    }

    try {
      if (!Platform.isIOS) {
        // Android/web: go ahead
        topics = await SegmentService().applySubscriptions();
      } else {
        // iOS: wait for APNs token before touching topics
        String? apns;
        for (int i = 0; i < 20; i++) {
          apns = await FirebaseMessaging.instance.getAPNSToken();
          if (apns != null) break;
          await Future.delayed(const Duration(milliseconds: 300));
        }

        if (apns != null) {
          topics = await SegmentService().applySubscriptions();
        } else {
          // Simulator or permission denied – skip topics instead of crashing
          debugPrint('APNs token still null; skipping SegmentService topics');
        }
      }
    } catch (e) {
      debugPrint('SegmentService.applySubscriptions failed: $e');
      topics = const [];
    }

    if (!mounted) return;
    setState(() {
      _token = token;
      _appliedTopics = topics;
    });
  }

  void _initNotificationsOnce() {
    if (_notifInitStarted) return;
    _notifInitStarted = true;

    // fire & forget, no blocking in build
    Future(() async {
      final notif = NotificationService();
      await notif.initLocalNotifications();
      await notif.init();
    });
  }

  List<MainScreenName> _visibleTabs(UserRoles roles) {
    return kBranchOrder.where((s) {
      if (!s.showNav) return false;
      if (s == MainScreenName.admin && !roles.isAdmin) return false;
      if (s == MainScreenName.venues && !(roles.isOwner || roles.isAdmin)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ This is the correct place for ref.listen in a ConsumerStatefulWidget
    ref.listen<AsyncValue<int>>(
      favoritesCountProvider,
      (prev, next) {
        final prevValue = prev?.value ?? 0;
        final nextValue = next.value ?? 0;

        // Only when user goes from 0 -> >0 favorites
        if (nextValue > 0 && prevValue == 0) {
          _initNotificationsOnce();
        }
      },
    );

    final roles = ref.watch(userRolesProvider);
    final tabs = _visibleTabs(roles);

    final MainScreenName activeGlobal =
    kBranchOrder[widget.nav.currentIndex];
    final currentVisibleIndex =
    tabs.indexOf(activeGlobal).clamp(0, tabs.length - 1);

    final pendingCount = ref.watch(pendingRequestsCountProvider);

    return MainScaffold(
      appBar: MainAppBar(screen: activeGlobal),
      body: widget.nav,
      bottomNavigationBar: MainBottomNavigationBar(
        tabs: tabs,
        currentIndex: currentVisibleIndex,
        onTap: (i) {
          final target = tabs[i];
          final branchIndex = kBranchOrder.indexOf(target);
          widget.nav.goBranch(
            branchIndex,
            initialLocation: branchIndex == widget.nav.currentIndex,
          );
        },
        socialBadgeCount: pendingCount,
      ),
    );
  }
}