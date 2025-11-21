// lib/features/explore/filters/popup_widgets/card_section.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';

class CardSection extends StatelessWidget {
  const CardSection({
    super.key,
    required this.title,
    this.trailing,
    required this.child,
    this.contentHorizontalPadding = horizontalSpacerDefault,
  });

  final String title;
  final Widget? trailing;
  final Widget child;
  final double contentHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            horizontalSpacerLarge,
            horizontalSpacerSmall,
            horizontalSpacerLarge,
            horizontalSpacerSmall,
          ),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            contentHorizontalPadding,
            6,
            contentHorizontalPadding,
            0,
          ),
          child: child,
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalSpacerDefault,
          ),
          child: Divider(
            color: grey,
            height: 0,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
