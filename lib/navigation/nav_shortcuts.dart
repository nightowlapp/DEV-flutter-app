// lib/navigation/nav_shortcuts.dart
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:nightowlcode/navigation/route_args.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/data/providers/map_nav_providers.dart';
import '../data/services/media_existence.dart';

extension ScreenNameRouting on MainScreenName {
  String get routeName => name;
  String get path => '/$name';
}

extension NavShortcuts on BuildContext {
  void goScreen(MainScreenName screen) {
    final scaffold = Scaffold.maybeOf(this);
    scaffold?.closeEndDrawer();
    scaffold?.closeDrawer();
    GoRouter.of(this).goNamed(screen.routeName);
  }

  Future<T?> pushNamedPage<T extends Object?>(String routeName,
      {Object? extra}) {
    return GoRouter.of(this).pushNamed<T>(routeName, extra: extra);
  }

  void replaceNamedPage(String routeName, {Object? extra}) {
    GoRouter.of(this).replaceNamed(routeName, extra: extra);
  }

  Future<T?> pushVenue<T extends Object?>(Venue v,
      {VenueMediaHealth? media, LatLng? userLoc}) {
    return GoRouter.of(this).pushNamed<T>(
      'venue',
      pathParameters: {'id': v.id},
      extra: VenueMainArgs(venue: v, media: media, userLoc: userLoc),
    );
  }

  /// Switch to Map tab, wait a tick so listeners attach, then command the map.
  Future<void> goToMapAndFocusVenue(WidgetRef ref, Venue v,
      {double zoom = 16}) async {
    final scaffold = Scaffold.maybeOf(this);
    scaffold?.closeEndDrawer();
    scaffold?.closeDrawer();

    goScreen(MainScreenName.map);

    await SchedulerBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 1));

    ref.read(mapNavControllerProvider.notifier).flyToVenue(
          v,
          zoom: zoom,
        );
  }
}
