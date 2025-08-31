import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/values.dart';

import '../../../../shared/constants/colors.dart';

/// A reusable, customizable date picker box with a Cupertino scroll wheel.
/// - Shows hint when no date is selected.
/// - Colors the text red when selected date is under [legalAge].
/// - Colors the text orange when selected date is >= [legalAge].
/// - Saves selection when tapping outside or pressing "Done".
/// - Clears selection when pressing "Cancel".
class DatePicker extends StatefulWidget {
  const DatePicker({
    super.key,
    this.initialDate,
    this.onChanged,
    this.hintText = 'Birthdate',
    this.legalAge = 18,
    this.backgroundColor = transparent,
    this.borderColor = white,
    this.borderWidth = 2.0,
    this.borderRadius = borderRadiusSmall,
    this.textColor = white,
    this.hintColor = grey,
    this.tooYoungColor = red,
    this.legalAgeColor = owlOrange,
    this.fontSize = 14.0,
    this.contentPadding =
    const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
    this.restrictPickerToLegalAge = false,
    this.barrierColor = const Color(0x99000000),
    this.sheetBackgroundColor = black,
    this.wheelMagnification = 1.1,
    this.wheelSqueeze = 1.2,
    this.wheelDiameterRatio = 1.1,
  });

  final DateTime? initialDate;
  final ValueChanged<DateTime>? onChanged;

  final String hintText;
  final int legalAge;

  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  final Color textColor;
  final Color hintColor;
  final Color tooYoungColor;
  final Color legalAgeColor;
  final double fontSize;

  final EdgeInsets contentPadding;

  /// If true, the picker won't allow choosing dates newer than "legal age ago".
  final bool restrictPickerToLegalAge;

  /// Bottom sheet styling/tuning
  final Color barrierColor;
  final Color sheetBackgroundColor;
  final double wheelMagnification;
  final double wheelSqueeze;
  final double wheelDiameterRatio;

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final DateTime legalAgeAgo =
    DateTime(today.year - widget.legalAge, today.month, today.day);

    final bool showHint = _selectedDate == null;
    final bool isTooYoung =
        _selectedDate != null && _selectedDate!.isAfter(legalAgeAgo);

    final Color labelColor = showHint
        ? widget.hintColor
        : (isTooYoung ? widget.tooYoungColor : widget.legalAgeColor);

    return GestureDetector(
      onTap: _openDatePickerWheel,
      child: Container(
        padding: widget.contentPadding,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          border:
          Border.all(color: widget.borderColor, width: widget.borderWidth),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Center(
          child: Text(
            showHint ? widget.hintText : _formatDate(_selectedDate!),
            style: TextStyle(
              color: labelColor,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDatePickerWheel() async {
    final now = DateTime.now();
    final legalAgeAgo =
    DateTime(now.year - widget.legalAge, now.month, now.day);

    final minDate = DateTime(1900);
    final maxDate = widget.restrictPickerToLegalAge ? legalAgeAgo : now;

    // Ensure initial is inside [minDate, maxDate]
    DateTime initial = _selectedDate ?? legalAgeAgo;
    if (initial.isAfter(maxDate)) initial = maxDate;
    if (initial.isBefore(minDate)) initial = minDate;

    DateTime temp = initial;

    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: widget.barrierColor,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: widget.sheetBackgroundColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false), // cancel
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      const Text(
                        'Select birthdate',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true), // save
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 216,
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.dark,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(fontSize: 20),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: initial,
                      minimumDate: minDate,
                      maximumDate: maxDate,
                      use24hFormat: true,
                      backgroundColor: widget.sheetBackgroundColor,
                      onDateTimeChanged: (d) => temp = d,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );

    // saved == true  -> explicit "Done"
    // saved == null  -> tap outside / drag down => SAVE
    // saved == false -> "Cancel" => CLEAR
    if (saved == false) {
      setState(() => _selectedDate = null);
      return;
    }

    setState(() => _selectedDate = temp);
    widget.onChanged?.call(temp);
  }

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)} / ${two(dt.month)} / ${dt.year}';
  }
}
