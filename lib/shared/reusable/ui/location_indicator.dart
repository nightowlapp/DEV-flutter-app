import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/reusable/ui/buttons.dart';
import 'package:nightowlcode/shared/reusable/ui/owl_snack.dart';

enum LocationIndicatorState { on, off, blocked }

/// Single source of truth for the indicator state:
/// - off      : user turned it off in-app
/// - blocked  : user on, but OS services/permission not available
/// - on       : user on AND OS services/permission OK
final locationIndicatorStateProvider =
    FutureProvider.family<LocationIndicatorState, bool>(
        (ref, enabledByUser) async {
  if (!enabledByUser) return LocationIndicatorState.off;

  final servicesEnabled = await Geolocator.isLocationServiceEnabled();
  final perm = await Geolocator.checkPermission();
  final granted = perm == LocationPermission.always ||
      perm == LocationPermission.whileInUse;

  return (servicesEnabled && granted)
      ? LocationIndicatorState.on
      : LocationIndicatorState.blocked;
});

class LocationIndicator extends ConsumerWidget {
  const LocationIndicator({
    super.key,
    required this.enabledByUser,
    required this.onToggleRequested,
    this.size = iconSizeDefault,
  });

  final bool enabledByUser;
  final VoidCallback onToggleRequested;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(locationIndicatorStateProvider(enabledByUser));

    return stateAsync.when(
      data: (s) {
        final isOn = s == LocationIndicatorState.on;
        final color = isOn ? blue : grey; // blue ON, grey OFF/blocked

        return Tooltip(
          message:
              isOn ? 'Location tracking is ON' : 'Location tracking is OFF',
          child: IconButton(
            icon: Icon(locationPinIcon, size: size, color: color),
            onPressed: () => _showDisclosureSheet(context,
                isOn: isOn, blocked: s == LocationIndicatorState.blocked),
            visualDensity: VisualDensity.compact,
            splashRadius: 18,
          ),
        );
      },
      loading: () => Icon(locationPinIcon, size: size, color: grey),
      error: (_, __) => Icon(locationPinIcon, size: size, color: grey),
    );
  }

  Future<void> _showDisclosureSheet(BuildContext context,
      {required bool isOn, required bool blocked}) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(locationPinIcon, color: isOn ? blue : grey),
              const SizedBox(width: 8),
              Text('Location sharing', style: Styles.basicTextHeader),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: grey),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              isOn
                  ? 'Your location may be accessed while using the app to help you find venues and friends.'
                  : 'Location sharing is off. Turn it on to enable nearby results.',
              style: Styles.basicText,
            ),
            if (blocked) ...[
              const SizedBox(height: 10),
              Text(
                'Looks like device services or permissions are off. You can enable them in Settings.',
                style: Styles.basicText.copyWith(color: greyLighter),
              ),
            ],
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OwlButton(
                  label: isOn ? 'Turn OFF' : 'Turn ON',
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onToggleRequested();
                    OwlSnack.show(
                      context,
                      title:
                          isOn ? 'Location sharing off' : 'Location sharing on',
                      variant: OwlSnackVariant.success,
                    );
                  },
                  backgroundColor: isOn ? transparent : owlPurple,
                  textColor: isOn ? red : white,
                  borderColor: isOn ? red : transparent,
                  borderRadius: borderRadiusSmall,
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OwlButton(
                  label: 'OS Settings',
                  onPressed: () async {
                    // App permission screen; then general location screen
                    await Geolocator.openAppSettings();
                    await Geolocator.openLocationSettings();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  backgroundColor: transparent,
                  textColor: white,
                  borderColor: grey,
                  borderRadius: borderRadiusSmall,
                  fullWidth: true,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              'We only use location as described in the app and privacy policy. You can change this anytime.',
              style:
                  Styles.basicText.copyWith(color: greyLighter, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
