import 'package:flutter/material.dart';
import 'package:go_router/src/misc/errors.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/assets.dart';

class ErrorScreen extends StatelessWidget {
  //TODO SEND CRAHC
  const ErrorScreen(
      {super.key,
      this.imagePath = ImagePaths.logo,
      this.borderColor = owlPurple,
      this.borderWidth = 1.5,
      this.backgroundColor = black,
      this.imageSize = 120,
      this.borderRadius = borderRadiusDefault,
      this.slogan = 'Woops something went wrong',
      this.sloganStyle,
      this.error});

  final String imagePath;
  final Color borderColor;
  final double borderWidth;
  final Color backgroundColor;
  final double imageSize;
  final double borderRadius;
  final String slogan;
  final TextStyle? sloganStyle;
  final Error? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
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
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}
