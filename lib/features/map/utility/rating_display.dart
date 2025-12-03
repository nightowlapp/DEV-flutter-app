// lib/shared/reusable/ui/rating_display.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';

import '../../../shared/constants/values.dart';

class RatingDisplay extends StatelessWidget {
  const RatingDisplay({
    super.key,
    required this.rating,
    required this.count,
    this.starColor = orange,
    this.inactiveStarColor = grey,
    this.textColor = white,
    this.fontSize = fontSizeSmall,
    this.starSize = iconSizeSmall,
    this.useDecimalComma = true,
  });

  /// Current average rating, 0..5
  final double rating;

  /// Total number of ratings/reviews
  final int count;

  /// Active star color (defaults to amber)
  final Color? starColor;

  /// Inactive star color (defaults to 30% white)
  final Color? inactiveStarColor;

  /// Text color (defaults to 87% white)
  final Color? textColor;

  /// Font size for leading number and count
  final double fontSize;

  /// Icon size for stars
  final double starSize;

  /// If true, formats 4.1 as "4,1"
  final bool useDecimalComma;

  @override
  Widget build(BuildContext context) {
    final clamped = rating.clamp(0, 5).toDouble();
    final active = starColor;
    final inactive = inactiveStarColor;
    final tColor = textColor;

    String _fmt(double r) {
      final s = r.toStringAsFixed(1);
      return useDecimalComma ? s.replaceAll('.', ',') : s;
    }

    List<Widget> _buildStars() {
      final widgets = <Widget>[];
      for (var i = 1; i <= 5; i++) {
        final diff = clamped - i;
        // Match the screenshot style: full stars until floor(rating),
        // then border (no halves). If you want halves, swap logic below.
        final icon = diff >= 0 ? Icons.star : Icons.star_border;
        widgets.add(
            Icon(icon, size: starSize, color: diff >= 0 ? active : inactive));
      }
      return widgets;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Leading number
        Text(
          _fmt(clamped),
          style: Styles.basicText,
        ),
        const SizedBox(width: 2),
        // Stars
        Row(children: _buildStars()),
        const SizedBox(width: 2),
        // Count in parentheses
        Text('(${count.clamp(0, 999999)})',
            style: Styles.smallText.copyWith(color: greyLighter)),
      ],
    );
  }
}
