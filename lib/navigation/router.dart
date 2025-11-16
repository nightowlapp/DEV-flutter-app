// lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nightowlcode/features/explore/widgets/venue_main_screen.dart';

// Auth/onboarding
import 'package:nightowlcode/features/login/widgets/login_nightowl_screen.dart';
import 'package:nightowlcode/features/login/widgets/login_or_create_account_screen.dart';
import 'package:nightowlcode/features/profile/widgets/other_profile_screen.dart';
import 'package:nightowlcode/features/signup/widgets/choose_favorite_venues_screen.dart';
import 'package:nightowlcode/features/signup/widgets/first_create_nightowl_profile_screen.dart';

// Tabs + shell
import 'package:nightowlcode/features/main/presentation/main_shell.dart';
import 'package:nightowlcode/features/explore/widgets/explore_screen.dart';
import 'package:nightowlcode/features/map/widgets/map_screen.dart';
import 'package:nightowlcode/features/profile/widgets/my_profile_screen.dart';
import 'package:nightowlcode/features/calender/widgets/calender_screen.dart';

// Standalone
import 'package:nightowlcode/features/map/widgets/venue_popup.dart';
import 'package:nightowlcode/features/settings/widgets/settings_screen.dart';
import 'package:nightowlcode/features/signup/widgets/fourth_create_nightowl_profile_screen.dart';
import 'package:nightowlcode/features/signup/widgets/optional_details_screen.dart';
import 'package:nightowlcode/features/signup/widgets/third_create_nightowl_profile_screen.dart';
import 'package:nightowlcode/navigation/route_args.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_screen.dart';

import '../features/admin/widgets/admin_screen.dart';
import '../features/explore/utility/bar_card_screen.dart';
import '../features/explore/widgets/more_info_screen.dart';
import '../features/main/presentation/main_screen_wrapper.dart';
import '../features/signup/widgets/second_create_nightowl_profile_screen.dart';
import '../features/social/widgets/social_screen.dart';

typedef ScreenBuilderWithKey = Widget Function(Key? key);
final List<MainScreenName> kBranchOrder =
    List<MainScreenName>.unmodifiable(_rootBuilders.keys);

// --- Tab root registry (single source of truth) ---
final Map<MainScreenName, ScreenBuilderWithKey> _rootBuilders = {
  MainScreenName.explore: (key) => ExploreScreen(key: key),
  MainScreenName.map: (key) => MapScreen(key: key),
  MainScreenName.calender: (key) => CalenderScreen(key: key),
  MainScreenName.social: (key) => SocialScreen(key: key),
  MainScreenName.profile: (key) => MyProfileScreen(key: key),

  // Placeholders to keep API stable
  MainScreenName.venues: (key) => const Center(child: Text('Venues')),
  MainScreenName.admin: (key) => const AdminScreen(),
};

Widget _buildRoot(MainScreenName s, Key key) {
  final builder = _rootBuilders[s];
  assert(builder != null, 'No builder registered for $s in _rootBuilders');

  final content = builder!(key); // the screen itself
  return MainScreenWrapper(screen: s, child: content);
}

// --- Router ---
final GoRouter router = GoRouter(
  // Start here (no invalid redirect needed)
  initialLocation: '/login-or-create',
  // ScreenName.explore.name,

  routes: [
    // Auth / onboarding
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: LoginScreen()),
    ),
    GoRoute(
      path: '/login-or-create',
      name: 'loginOrCreate',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: LoginOrCreateAccountScreen()),
    ),
    GoRoute(
      path: '/first-create-nightowl-profile',
      name: 'firstCreateNightowlProfile',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: FirstCreateNightowlProfileScreen()), //TODO
    ),
    GoRoute(
      path: '/second-create-nightowl-profile',
      name: 'secondCreateNightowlProfile',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: SecondCreateNightowlProfileScreen()),
    ),
    GoRoute(
      path: '/third-create-nightowl-profile',
      name: 'thirdCreateNightowlProfile',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: ThirdCreateNightowlProfileScreen()),
    ),
    GoRoute(
      path: '/fourth-create-nightowl-profile',
      name: 'fourthCreateNightowlProfile',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: FourthCreateNightowlProfileScreen()),
    ),
    GoRoute(
      path: '/choose-favorite-venues',
      name: 'chooseFavoriteVenues',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: ChooseFavoriteVenuesScreen()),
    ),
    // GoRoute(
    //   path: '/optional-details',
    //   name: 'optionalDetails',
    //   pageBuilder: (context, state) =>
    //   const NoTransitionPage(child: OptionalDetailsScreen()),
    // ),

    // Standalone
    GoRoute(
      path: '/venue/:id',
      name: 'venue',
      pageBuilder: (context, state) {
        final args = state.extra as VenueMainArgs?;
        if (args == null) {
          return const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('Missing Venue'))),
          );
        }
        return NoTransitionPage(
          child: VenueMainScreen(
            venue: args.venue,
            media: args.media,
            userLoc: args.userLoc,
          ),
        );
      },
    ),
    GoRoute(
      path: '/settings',
      name: SettingsScreen.routeName,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: SettingsScreen()),
      // const NoTransitionPage(child: LoadingScreen()),
    ),
    // in your router config
    GoRoute(
      path: '/more-info',
      name: MoreInfoScreen.routeName,
      builder: (context, state) {
        final args = state.extra as VenueMoreInfoArgs;
        return MoreInfoScreen(
          venue: args.venue,
          media: args.media,
          userLoc: args.userLoc,
        );
      },
    ),
    GoRoute(
      path: '/bar-card',
      name: BarCardScreen.routeName, // 'barCard'
      pageBuilder: (context, state) {
        final args = state.extra as BarCardArgs?;
        if (args == null) {
          return const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('Missing BarCardArgs'))),
          );
        }
        return NoTransitionPage(child: BarCardScreen(args: args));
      },
    ),
    GoRoute(
      path: '/other-profile',
      name: 'otherProfile',
      pageBuilder: (context, state) {
        final uid = state.extra as String?;
        if (uid == null) {
          return const NoTransitionPage(
            child: Scaffold(
              body: Center(child: Text('Missing user')),
            ),
          );
        }
        return NoTransitionPage(
          child: OtherProfileScreen(uid: uid),
        );
      },
    ),

    // GoRoute(
    //   path: '/test',
    //   name: 'test',
    //   pageBuilder: (context, state) =>
    //   const NoTransitionPage(child: VenuePopup(id: 'Test')),
    // ),

    // Tab shell (IndexedStack keeps roots mounted)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navShell) => MainShell(nav: navShell),
      branches: [
        for (final s in kBranchOrder) // <-- use canonical order here
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/${s.name}',
                name: s.name,
                pageBuilder: (context, state) => NoTransitionPage(
                    child: _buildRoot(s, PageStorageKey(s.name))),
              ),
            ],
          ),
      ],
    ),
  ],

  errorPageBuilder: (context, state) => MaterialPage(
    child: Scaffold(
      body: Center(child: Text('Route error: ${state.error}')),
    ),
  ),
);
