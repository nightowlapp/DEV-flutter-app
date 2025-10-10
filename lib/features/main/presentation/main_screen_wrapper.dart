// lib/features/main/presentation/main_screen_wrapper.dart
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nightowlcode/data/services/location/location_controller.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

import '../../../data/services/location/location_gate.dart';

/// One place to add global concerns for main tabs:
/// - Location gating
/// - App-wide providers/inheriteds
/// - ErrorBoundary, theming, etc.
class MainScreenWrapper extends StatelessWidget {
  const MainScreenWrapper({
    super.key,
    required this.screen,
    required this.child,
  });

  final MainScreenName screen;
  final Widget child;

  bool get _requiresLocationScreen {
    switch (screen) {
      case MainScreenName.explore:
      case MainScreenName.map:
      case MainScreenName.social:
      case MainScreenName.calender:
        // TODO Other needed for location?
        return true;
      default:
        return false;
    }
  }

  bool get locationServiceAllowed {
    //TODO Find smart way to get current permission.
// if(Geolocator.checkPermission() == LocationPermission.whileInUse ||
// Geolocator.checkPermission() == LocationPermission.always)
    return true;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Add more cross-cutting wrappers here if needed:
    // content = SomeInherited(scope: ..., child: content);

    if (_requiresLocationScreen && !locationServiceAllowed) {
      content = LocationGate(child: content);
    }

    return content;
  }
}
