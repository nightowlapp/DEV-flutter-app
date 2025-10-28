// lib/shared/reusable/ui/edit_badge.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';

class EditBadge extends StatelessWidget {
  const EditBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: black,
        borderRadius: BorderRadius.circular(borderRadiusSmall),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(editIcon, color: grey, size: iconSizeMedium),
          Text('Edit',              style: Styles.smallText.copyWith(fontSize: 6)),
        ],
      ),
    );
  }
}
