// tracking_consent.dart
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the current ATT status in memory.
final trackingStatusProvider =
    StateProvider<TrackingStatus>((_) => TrackingStatus.notDetermined);

/// Call this once on iOS startup to show ATT (if needed) and store the status.
final trackingInitProvider = FutureProvider<void>((ref) async {
  if (!Platform.isIOS) {
    ref.read(trackingStatusProvider.notifier).state =
        TrackingStatus.notSupported;
    return;
  }

  var status = await AppTrackingTransparency.trackingAuthorizationStatus;

  if (status == TrackingStatus.notDetermined) {
    status = await AppTrackingTransparency.requestTrackingAuthorization();
  }

  ref.read(trackingStatusProvider.notifier).state = status;
});

/// Helper: is tracking allowed according to ATT?
bool isTrackingAllowed(Ref ref) {
  final status = ref.read(trackingStatusProvider);
  return status == TrackingStatus.authorized;
}
