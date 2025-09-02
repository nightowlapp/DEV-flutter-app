// lib/features/venue/widgets/rating_card.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/icons.dart'; // for filledStarIcon / halfFilledStarIcon / emptyStarIcon

class RatingCard extends StatelessWidget {
  RatingCard({
    super.key,
    required this.venue,
    this.width = 130,
    this.starColor = owlOrange,
    this.badgeBorderColor = owlOrange,
    this.textColor = white,
    this.backgroundColor = Colors.transparent,
    this.showCount = true,
  });

  final Venue venue;

  /// Layout/visual knobs
  final double width;
  final Color starColor;
  final Color badgeBorderColor;
  final Color textColor;
  final Color backgroundColor;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final double rating = venue.rating ?? 0.0;
    final String countText =
    showCount ? '(${_formatRatingCount(venue.ratingCount)})' : '';

    return SizedBox(
      width: width,
      child: Container(
        color: backgroundColor, // keep transparent unless you want a fill
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // numeric badge
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(
                color: black,
                border: Border.all(color: badgeBorderColor, width: 2),
                borderRadius: BorderRadius.circular(borderRadiusSmall),
              ),
              child: Text(
                (venue.rating == null) ? '' : rating.toStringAsFixed(1),
                style: Styles.boldText.copyWith(color: textColor),
              ),
            ),

            const SizedBox(width: 6),

            // stars + small rating count (bottom-right)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      final filled = rating >= idx;
                      final half = rating >= (idx - 0.5) && rating < idx;
                      return Icon(
                        filled
                            ? filledStarIcon
                            : (half ? halfFilledStarIcon : emptyStarIcon),
                        color: starColor,
                        size: 14, // keep in sync with opening-hours chip
                      );
                    }),
                  ),
                  if (showCount) ...[
                    const SizedBox(height: 2),
                    Text(
                      countText,
                      style: Styles.smallText.copyWith(
                        fontSize: 9,
                        color: textColor.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- internal logic --------------------------------------------------------

  String _formatRatingCount(int n) {
    if (n >= 1000000) {
      final d = n / 1000000;
      return d >= 10 ? '${d.toStringAsFixed(0)}M' : '${d.toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      final d = n / 1000;
      return d >= 10 ? '${d.toStringAsFixed(0)}k' : '${d.toStringAsFixed(1)}k';
    }
    return n.toString();
  }
}
