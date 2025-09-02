import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/information_popup.dart';

import '../../../../shared/constants/icons.dart';

typedef DurationSelected = void Function(int minutes);

class SafetyModeToggle extends StatelessWidget {
  /// Visual state (default off)
  final bool isOn;

  /// Called when switch toggles (no-op by default)
  final ValueChanged<bool>? onChanged;

  /// Trusted contacts count (badge text)
  final int trustedContactsCount;

  /// Haptics enabled
  final bool enableHaptics;

  const SafetyModeToggle({
    super.key,
    this.isOn = false,
    this.onChanged,
    this.trustedContactsCount = 0,
    this.enableHaptics = true,
  });

  @override
  Widget build(BuildContext context) {
    final _onChanged = onChanged ?? (_) {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Safety Mode', style: Styles.boldText),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child:
              GestureDetector(child: 
                Icon(
                  infoIcon,
                  color: owlOrange,
                  size: iconSizeDefault,
                ),
              // onTap: InformationPopup(title: '', children: [],),
              ),
              //TODO onpress EXPLAIn.
            ),
            Align(
              alignment: Alignment.centerRight,
              // ---------- smooth appear/disappear for right counter ----------
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: isOn
                  ? Text.rich(
                    key: const ValueKey('count_on'),
                    TextSpan(
                      text: '$trustedContactsCount',
                      style: trustedContactsCount > 2
                        ? Styles.boldText.copyWith(color: green)
                        : Styles.boldText.copyWith(color: red),
                    ),
                    style: Styles.boldText,
                  )
                  : const SizedBox.shrink(key: ValueKey('count_off')),
              ),
            )
          ],
        ),

        const SizedBox(height: verticalSpacerSmall),

        Center(
          child: SizedBox(
            width: PlatformConfig.width(context) * 0.16, // ~16% of screen width
            child: FittedBox(
              child: Switch.adaptive(
                value: isOn,
                onChanged: (v) {
                  if (enableHaptics) HapticFeedback.heavyImpact();
                  _onChanged(v);
                },
                activeColor: green,
                inactiveThumbColor: red,
                inactiveTrackColor: grey.withOpacity(0.35),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ),

        const SizedBox(height: verticalSpacerSmall),

        Row(
          children: [
            Expanded(
              // ---------- smooth swap between "Not sharing" and "Sharing..." ----------
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 2000),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SizeTransition(
                    sizeFactor: anim,
                    axisAlignment: -1.0, // grow from top for tidy layout
                    child: child,
                  ),
                ),
                child: !isOn
                  ? Text.rich(
                    key: const ValueKey('status_off'),
                    TextSpan(
                      children: [
                        TextSpan(
                          // text: 'Not',
                          style:
                          Styles.boldText.copyWith(color: red), // red
                        ),
                        // const TextSpan(text: ' sharing location'),
                        const TextSpan(text: ''),
                      ],
                    ),
                    textAlign: TextAlign.left,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: Styles.boldText,
                  )
                  : // Replace only the ON case Text.rich with the version below (adds soft break hints)
                  Text.rich(
                    key: const ValueKey('status_on'),
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Informing\u200B'),
                        TextSpan(
                          text: '$trustedContactsCount',
                          style: Styles.boldText.copyWith(
                            color: trustedContactsCount == 0 ? red : green,
                          ),
                        ),
                        const TextSpan(text: '\u200B'), // allow wrap right before "trusted"
                        TextSpan(
                          text: ' trusted ',
                          style: Styles.boldText.copyWith(color: green),
                        ),
                        TextSpan(
                          text: 'contact${trustedContactsCount == 1 ? '' : 's'}',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.left,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: Styles.boldText,
                  )

              ),
            ),
          ],
        ),
      ],
    );
  }
}
