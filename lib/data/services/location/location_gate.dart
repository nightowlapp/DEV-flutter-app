// lib/features/location/location_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/reusable/ui/popup_dialog_default.dart'; // adjust path

import '../../../shared/reusable/ui/owl_dialogs.dart';
import 'location_controller.dart';
import 'location_status.dart';

class LocationGate extends ConsumerStatefulWidget {
  const LocationGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LocationGate> createState() => _LocationGateState();
}

class _LocationGateState extends ConsumerState<LocationGate> {
  bool _dialogOpen = false;

  void _maybeShowDialog(LocationStatus status) {
    if (!mounted || _dialogOpen || status.ready) return;

    final ctrl = ref.read(locationControllerProvider.notifier);

    String title = '';
    String body = '';
    List<Widget> actions = [];

    if (!status.servicesEnabled) {
      title = 'Enable Location Services';
      body = 'This app needs location services to work.';
      actions = [
        _actionButton('Open Location Settings', () async {
          await ctrl.openAppSettings();
        }),
        const SizedBox(height: verticalSpacerSmall),
      ];
    } else if (status.isDenied) {
      title = 'Allow Location Access';
      body = 'We use your location to show nearby venues.';
      actions = [
        _actionButton('Grant Permission', () async => ctrl.requestPermission()),
      ];
    } else if (status.isDeniedForever) {
      title = 'Permission Required';
      body =
      'Location permission is permanently denied. Please enable it in Settings.';
      actions = [
        _actionButton('Open App Settings', () async => ctrl.openAppSettings()),
      ];
    } else {
      title = 'Checking Location…';
      body = 'Hold on while we verify your location setup.';
      actions = [
        _actionButton('Retry', () async => ctrl.requestPermission()),
      ];
    }

    _dialogOpen = true;
    OwlDialogs.show(
      context: context,
      child: PopupDialogDefault(
        title: title,
        children: [
          Text(body, style: Styles.popupText),
          const SizedBox(height: verticalSpacerDefault),
          ...actions,
        ],
      ),
    ).then((_) {
      if (mounted) _dialogOpen = false;
    });
  }

  Widget _actionButton(String label, Future<void> Function() onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: owlOrange.withOpacity(0.15),
          foregroundColor: white,
          side: const BorderSide(color: grey, width: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusDefault),
          ),
        ),
        onPressed: () async {
          await onTap();
          // Ask for a quick refresh; controller also polls.
          await ref.read(locationControllerProvider.notifier).refresh();
        },
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(locationControllerProvider);

    // Listen in build (allowed). Close dialog when ready.
    ref.listen<LocationStatus>(locationControllerProvider, (prev, next) {
      if (!mounted) return;
      if (next.ready) {
        if (_dialogOpen) {
          Navigator.of(context, rootNavigator: true).maybePop();
          _dialogOpen = false;
        }
      } else {
        // Open after this frame to avoid calling showDialog during build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeShowDialog(next);
        });
      }
    });

    // Ensure first mount also shows dialog if needed
    if (!status.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowDialog(status);
      });
    }

    // Always render the child; dialog blocks until ready.
    return widget.child;
  }
}
