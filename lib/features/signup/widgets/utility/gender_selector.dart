// lib/shared/reusable/ui/gender_hybrid_picker_card.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/reusable/ui/buttons.dart';

import '../../../../shared/constants/enums.dart';

/// Keep this enum consistent with your existing one.
/// If you already declared GenderOption elsewhere, remove one to avoid conflicts.

extension GenderX on Gender {
  String get code => switch (this) {
    Gender.female => 'F',
    Gender.male => 'M',
    Gender.other => 'O',
  };

  String get label => switch (this) {
    Gender.female => 'Female',
    Gender.male => 'Male',
    Gender.other => 'Other',
  };

  IconData get icon => switch (this) {
    Gender.female => femaleIcon,
    Gender.male => maleIcon,
    Gender.other => otherGenderIcon,
  };
}

/// Hybrid UI:
/// - Outer bordered card (black bg, white stroke).
/// - Centered title (no icon).
/// - Three equal-width selectable "small boxes" in a row.
///   Each box shows an icon inside; small text label sits *below* the box.
/// - Selection behavior matches your picker: selected gets owlOrange background,
///   unselected is transparent. Uses OwlButton under the hood.
///
/// Controlled:
///   pass [value] and update it in [onChanged].
/// Uncontrolled:
///   omit [value], optionally set [initialValue].
class GenderSelector extends StatefulWidget {
  const GenderSelector({
    super.key,
    required this.onChanged,
    this.title = 'Select Your Gender',
    this.value,
    this.initialValue,
    // Card
    this.cardColor = black,
    this.strokeColor = transparent,
    this.strokeWidth = 1.0,
    this.borderRadius = borderRadiusDefault,
    this.contentPadding = const EdgeInsets.fromLTRB(0, 5, 0, 5),
    // Layout
    this.gap = 10.0,
    this.boxSize = iconSizeMedium*1.5,
    // Box look (delegated to OwlButton for bg/border)
    this.activeBgColor = owlOrange,
    this.inactiveBgColor = transparent,
    this.activeBorderColor = white,
    this.inactiveBorderColor = white,
    this.boxBorderRadius = borderRadiusMedium,
    // Icon/Text
    this.iconColor = white,
    this.iconSize = iconSizeMedium,
    this.labelStyle =
    const TextStyle(color: white, fontSize: 12, fontWeight: FontWeight.w200),
    this.titleStyle =
    const TextStyle(color: white, fontSize: fontSizeMedium, fontWeight: FontWeight.w600),
  });

  final ValueChanged<Gender> onChanged;

  final String title;
  final TextStyle titleStyle;

  /// Controlled value (when provided).
  final Gender? value;

  /// Uncontrolled initial value.
  final Gender? initialValue;

  // Card frame
  final Color cardColor;
  final Color strokeColor;
  final double strokeWidth;
  final double borderRadius;
  final EdgeInsets contentPadding;

  // Layout
  final double gap;
  final double boxSize;

  // Box appearance
  final Color activeBgColor;
  final Color inactiveBgColor;
  final Color activeBorderColor;
  final Color inactiveBorderColor;
  final double boxBorderRadius;

  // Icon/text inside/below the box
  final Color iconColor;
  final double iconSize;
  final TextStyle labelStyle;

  @override
  State<GenderSelector> createState() => _GenderSelectorState();
}

class _GenderSelectorState extends State<GenderSelector> {
  Gender? _internal;
  bool get _isControlled => widget.value != null;

  @override
  void initState() {
    super.initState();
    if (!_isControlled) _internal = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant GenderSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isControlled && oldWidget.value != null) {
      _internal = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.value ?? _internal;

    return Container(
      decoration: ShapeDecoration(
        color: widget.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          side: BorderSide(color: widget.strokeColor, width: widget.strokeWidth),
        ),
      ),
      padding: widget.contentPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered title (no icon)
          Center(
            child: Text(widget.title, style: widget.titleStyle, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),

          // Row with three equal items
          Row(
            children: [
              Expanded(child: _optionTile(Gender.female, selected)),
              SizedBox(width: widget.gap),
              Expanded(child: _optionTile(Gender.male, selected)),
              SizedBox(width: widget.gap),
              Expanded(child: _optionTile(Gender.other, selected)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _optionTile(Gender option, Gender? selected) {
    final bool isSelected = selected == option;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Square selectable box
        SizedBox(
          height: widget.boxSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // OwlButton provides the interactive surface, bg, and border
              SizedBox.expand(
                child: OwlButton(
                  label: '', // empty label — we overlay the icon centered
                  fullWidth: true,
                  padding: EdgeInsets.zero,
                  borderRadius: widget.boxBorderRadius,
                  backgroundColor:
                  isSelected ? widget.activeBgColor : widget.inactiveBgColor,
                  textColor: widget.iconColor, // not used (no label), OK
                  borderColor:
                  isSelected ? widget.activeBorderColor : widget.inactiveBorderColor,
                  onPressed: () {
                    if (!_isControlled) setState(() => _internal = option);
                    widget.onChanged(option);
                  },
                ),
              ),
              // Centered icon (visual content)
              IgnorePointer(
                ignoring: true,
                child: Icon(option.icon, size: widget.iconSize, color: widget.iconColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(option.label, style: widget.labelStyle, textAlign: TextAlign.center),
      ],
    );
  }
}
