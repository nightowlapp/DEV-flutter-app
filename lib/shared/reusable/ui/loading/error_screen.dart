import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/assets.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    super.key,
    this.imagePath = ImagePaths.logo,
    this.borderColor = owlPurple,
    this.borderWidth = 1.5,
    this.backgroundColor = black,
    this.imageSize = 120,
    this.borderRadius = borderRadiusDefault,
    this.slogan = 'Woops',
    this.sloganStyle,
  });

  final String imagePath;
  final Color borderColor;
  final double borderWidth;
  final Color backgroundColor;
  final double imageSize;
  final double borderRadius;
  final String slogan;
  final TextStyle? sloganStyle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: imageSize + borderWidth * 2,
              height: imageSize + borderWidth * 2,
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: borderWidth),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Image.asset(
                  imagePath,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Claim the night',
              style: Styles.sloganTextGradient,
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}
