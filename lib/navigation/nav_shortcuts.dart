import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nightowlcode/navigation/route_args.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

import '../data/services/media_existence.dart';
import '../models/venues/venue.dart';
import '../shared/utility/lat_lng.dart';

/// Typed metadata for tab roots
extension ScreenNameRouting on MainScreenName {
  String get routeName => name;   // must match GoRoute.name
  String get path => '/$name';    // must match GoRoute.path
}

/// DRY navigation shortcuts
extension NavShortcuts on BuildContext {
  /// Switch to a tab/root (StatefulShellRoute branch) by ScreenName.
  /// Works because your GoRoutes are named after ScreenName.
  void goScreen(MainScreenName screen) {
    // Close drawers so UI doesn't linger over the new page.
    final scaffold = Scaffold.maybeOf(this);
    scaffold?.closeEndDrawer();
    scaffold?.closeDrawer();
    GoRouter.of(this).goNamed(screen.routeName);
  }

  /// Push a non-tab (standalone) page by its route *name*.
  Future<T?> pushNamedPage<T extends Object?>(String routeName, {Object? extra}) {
    return GoRouter.of(this).pushNamed<T>(routeName, extra: extra);
  }

  /// Replace current page with a non-tab page by its route *name*.
  void replaceNamedPage(String routeName, {Object? extra}) {
    GoRouter.of(this).replaceNamed(routeName, extra: extra);
  }
  Future<T?> pushVenue<T extends Object?>(
      Venue v, {
        VenueMediaHealth? media,
        LatLng? userLoc,
      }) {
    return GoRouter.of(this).pushNamed<T>(
      'venue',
      pathParameters: {'id': v.id},
      extra: VenueMainArgs(venue: v, media: media, userLoc: userLoc),
    );
  }
}


