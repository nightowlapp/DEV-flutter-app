import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/assets.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({
    super.key,
    this.imagePath = ImagePaths.logoDown,
    this.borderColor = owlPurple,
    this.borderWidth = 1,
    this.backgroundColor = transparent,
    this.imageSize = 150,
    this.borderRadius = borderRadiusDefault,
    this.slogan = 'Claim the night',
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
              style: Styles.sloganStyle,
              // Styles.logoCrazy('Claim the night'),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}
