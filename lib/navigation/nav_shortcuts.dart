import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:nightowlcode/features/explore/utility/bar_card_screen.dart';
import 'package:nightowlcode/navigation/route_args.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/data/providers/map_nav_providers.dart';
import 'package:nightowlcode/data/services/media_existence.dart';

// Optional: show the pullable popup from elsewhere
import 'package:nightowlcode/features/map/widgets/venue_popup.dart'
    show showVenuePopupSheet;

import '../features/explore/widgets/more_info_screen.dart';

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

    ref.read(mapNavControllerProvider.notifier).flyToVenue(v, zoom: zoom);
  }

  /// Same as [goToMapAndFocusVenue] but also opens the pullable popup.
  Future<void> goToMapFocusAndOpenVenue(
    WidgetRef ref,
    Venue v, {
    double zoom = 15,
    double popupInitialSize = 0.55,
  }) async {
    // 👇 Capture root navigator BEFORE closing drawer / awaiting.
    final rootNavigator = Navigator.of(this, rootNavigator: true);

    final scaffold = Scaffold.maybeOf(this);
    scaffold?.closeEndDrawer();
    scaffold?.closeDrawer();

    // Switch to the Map tab
    goScreen(MainScreenName.map);

    // Let the map screen mount and its listeners attach
    await SchedulerBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 1));

    // Tell the map nav controller to fly to the venue
    ref.read(mapNavControllerProvider.notifier).flyToVenue(v, zoom: zoom);

    // Give the camera a bit of time to animate before showing popup
    await Future.delayed(const Duration(milliseconds: 320));

    // Use the *root* navigator we captured earlier – no more dead context.
    await showVenuePopupSheet(
      rootNavigator.context,
      venue: v,
      initialSize: popupInitialSize,
      onClose: () => rootNavigator.maybePop(),
    );
  }

  /// Go to Explore tab, push Venue page, then push More Info page on top.
  Future<void> goToExploreVenueMoreInfo(
    Venue v, {
    VenueMediaHealth? media,
    LatLng? userLoc,
  }) async {
    final scaffold = Scaffold.maybeOf(this);
    scaffold?.closeEndDrawer();
    scaffold?.closeDrawer();

    // 1) switch to Explore tab
    goScreen(MainScreenName.explore);
    await Future.delayed(const Duration(milliseconds: 150));

    // 2) wait for Explore to mount
    await SchedulerBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 150));

    // 3) push Venue page (don't await; we want to stack More Info next)
    // ignore: unawaited_futures
    pushVenue(v, media: media, userLoc: userLoc);

    // 4) next frame, push More Info on top of Venue
    await SchedulerBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 150));

    await pushNamedPage(
      MoreInfoScreen.routeName,
      extra: VenueMoreInfoArgs(venue: v, media: media, userLoc: userLoc),
    );
  }

  Future<void> goToExploreVenueBarCard(
    Venue v, {
    VenueMediaHealth? media,
    LatLng? userLoc,
  }) async {
    final scaffold = Scaffold.maybeOf(this);
    scaffold?.closeEndDrawer();
    scaffold?.closeDrawer();

    // 1) switch to Explore tab
    goScreen(MainScreenName.explore);
    await Future.delayed(const Duration(milliseconds: 150));

    // 2) wait for Explore to mount
    await SchedulerBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 150));

    // 3) push Venue page (don't await; we want to stack More Info next)
    // ignore: unawaited_futures
    pushVenue(v, media: media, userLoc: userLoc);

    // 4) next frame, push More Info on top of Venue
    await SchedulerBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 150));

    await pushNamedPage(
      BarCardScreen.routeName,
      extra: BarCardArgs(
        venueId: v.id,
        venueName: v.displayName,
      ),
    );
  }
}
