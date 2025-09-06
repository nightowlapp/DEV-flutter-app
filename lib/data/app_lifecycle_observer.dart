// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../core/storage/app_storage.dart';
// import 'other_providers.dart';
//
// class AppLifecycleObserver extends ConsumerStatefulWidget {
//   final Widget child;
//
//   const AppLifecycleObserver({super.key, required this.child});
//
//   @override
//   ConsumerState<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
// }
//
// class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver>
//     with WidgetsBindingObserver {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) async {
//     if (state == AppLifecycleState.detached) {
//       final prefs = await ref.read(sharedPrefsFutureProvider.future);
//       final stayLoggedIn = prefs.getBool('stayLoggedIn') ?? true;
//       if (!stayLoggedIn) {
//         await ref.read(authRepositoryProvider).signOut();
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return widget.child;
//   }
// }