// lib/shared/reusable/users/party_status_indicator.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/utility/utility.dart';
import 'package:nightowlcode/shared/reusable/ui/popup_dialog_default.dart';

import '../../../data/providers/party_status/party_status_provider.dart';
import '../../constants/styles.dart';

class PartyStatusIndicator extends ConsumerStatefulWidget {
  const PartyStatusIndicator({super.key});

  @override
  ConsumerState<PartyStatusIndicator> createState() => _PartyStatusIndicatorState();
}

class _PartyStatusIndicatorState extends ConsumerState<PartyStatusIndicator>
  with SingleTickerProviderStateMixin {
  static const _cycleDuration = Duration(seconds: 12); // slow & subtle
  static const double _minOpacity = 0.2;
  static const double _maxOpacity = 0.8;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycleDuration)..stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Interpolate smoothly through the provider-supplied palette.
  Color _colorFromT(double t, List<Color> palette) {
    if (palette.isEmpty) return Colors.grey;
    final n = palette.length;
    final seg = ((t % 1.0) * n).floor();
    final a = palette[seg % n];
    final b = palette[(seg + 1) % n];
    final localT = ((t % 1.0) * n) - seg;
    return Color.lerp(a, b, Curves.easeInOut.transform(localT)) ?? a;
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(partyStatusStateProvider);          // chosen status (fast)
    final baseColor = ref.watch(partyStatusColorProvider);       // color for chosen status
    final needsAnswer = ref.watch(partyStatusNeedsAnswerProvider);
    final palette = ref.watch(partyStatusPulsePaletteProvider);  // colors to pulse through


    // Start/stop animation when "needsAnswer" changes.
    ref.listen<bool>(partyStatusNeedsAnswerProvider, (prev, next) {
        if (next) {
          if (!_controller.isAnimating) _controller.repeat();
        }
        else {
          if (_controller.isAnimating) _controller.stop();
        }
      }
    );

    // Ensure proper initial state on first build.
    if (needsAnswer && !_controller.isAnimating) {
      _controller.repeat();
    }
    else if (!needsAnswer && _controller.isAnimating) {
      _controller.stop();
    }

    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final picked = await _showStatusDialog(context, ref: ref, initial: status);
        if (picked == null) return;

        // Snappy global update
        ref.read(partyStatusStateProvider.notifier).state = picked;

        // Persist (local + cloud)
        final pos = await Geolocator.getCurrentPosition().catchError((_) => null);
        final store = ref.read(partyStatusStoreProvider);
        await store.saveStatus(
          picked,
          change: PartyStatusChange.manual,
          position: pos,
        );
        HapticFeedback.mediumImpact(); // TODO use more!
      },
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: iconSizeDefault,
        child: needsAnswer
          ? AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final s = math.sin(2 * math.pi * _controller.value); // -1..1
              final opacity = _minOpacity + (_maxOpacity - _minOpacity) * ((s + 1) / 2); // 0.2..0.8
              final col = _colorFromT(_controller.value, palette).withOpacity(opacity);
              return Icon(partyStatusIcon, size: iconSizeMedium, color: col);
            },
          )
          : Icon(partyStatusIcon, size: iconSizeMedium, color: baseColor),
      ),
    );
  }
}

Future<PartyStatusTypes?> _showStatusDialog(
  BuildContext context, {
    required WidgetRef ref,
    required PartyStatusTypes initial,
  }) {
  return showDialog<PartyStatusTypes>(
    context: context,
    builder: (dialogCtx) => PopupDialogDefault(
      title: 'Select Status',
      children: [
        for (final it in PartyStatusTypes.values)
          Builder(builder: (_) {
              final color = ref.read(partyStatusColorForProvider(it));
              final bg = color.withOpacity(0.14);
              return ListTile(
                selected: it == initial,
                selectedTileColor: bg,
                leading: Icon(partyStatusIcon, color: color, size: iconSizeDefault),
                title: Text(Utility.formatString(it.name), style: Styles.popupText),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(dialogCtx).pop<PartyStatusTypes>(it);
                },
              );
            }
          ),
      ],
    ),
  );
}
