// lib/shared/reusable/ui/simple_text_field.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';

import '../../constants/icons.dart';

/// A generic, customizable, but simple text field.
/// Minimal knobs, good defaults, no need to pass datatypes in the screens.
class SimpleTextField extends StatefulWidget {
  const SimpleTextField({
    super.key,
    required this.controller,
    this.hint = 'First Name',
    this.obscureText = false,
    this.enableObscureToggle = true,
    this.onChanged,
    this.validator,
    this.leadingIcon,
    this.trailingIcon,
    this.backgroundColor = transparent,
    this.textColor = owlPurple,
    this.hintColor = greyLighter,
    this.borderColor =white,
    this.focusedBorderColor = owlPurple,
    this.cursorColor = white,
    this.borderRadius = borderRadiusMedium,
    this.borderWidth = 1.5,
    this.contentPadding =
    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  });

  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final bool enableObscureToggle;

  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  final IconData? leadingIcon;
  final IconData? trailingIcon;

  final Color? backgroundColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? cursorColor;

  final double borderRadius;
  final double borderWidth;
  final EdgeInsets contentPadding;

  @override
  State<SimpleTextField> createState() => _SimpleTextFieldState();
}

class _SimpleTextFieldState extends State<SimpleTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    // sensible defaults for dark UI
    final Color bg = widget.backgroundColor ?? transparent;
    final Color fg = widget.textColor ?? owlPurple;
    final Color hc = widget.hintColor ?? grey;
    final Color bc = widget.borderColor ?? white;
    final Color fbc = widget.focusedBorderColor ?? owlPurple;
    final Color cc = widget.cursorColor ?? owlPurple;

    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(color: bc, width: widget.borderWidth),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(color: fbc, width: widget.borderWidth + 0.2),
    );

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      cursorColor: cc,
      style: TextStyle(color: fg),
      keyboardType: widget.obscureText ? TextInputType.visiblePassword : TextInputType.text,
      onChanged: widget.onChanged,
      validator: widget.validator,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: bg,
        hintText: widget.hint,
        hintStyle: TextStyle(color: hc),
        contentPadding: widget.contentPadding,
        prefixIcon: widget.leadingIcon == null
            ? null
            : Icon(widget.leadingIcon, color: white),
        suffixIcon: widget.obscureText && widget.enableObscureToggle
            ? IconButton(
          icon: Icon(
            _obscure ? invisible : visible,
            color: hc,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        )
            : (widget.trailingIcon == null
            ? null
            : Icon(widget.trailingIcon, color: hc)),
        border: baseBorder,
        enabledBorder: baseBorder,
        focusedBorder: focusedBorder,
      ),
    );
  }
}
