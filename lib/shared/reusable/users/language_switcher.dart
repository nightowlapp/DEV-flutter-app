import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';

import '../../../assets.dart';
import '../ui/owl_popup.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({
    super.key,
    this.radius = iconSizeMedium,
    this.borderRadius = borderRadiusDefault,
  });
  final double radius;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLanguageDialog(context),
      child: CircleAvatar(
        backgroundColor: transparent,
        radius: iconSizeDefault,
        child: Image.asset(ImagePaths.ukFlag,
          width: radius * 1.3,
          height: radius,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => OwlPopup(
        title: 'Select Language',
        children: [
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadiusSmallest),
              child: Image.asset(
                'assets/flags/uk.png',
                width: iconSizeMedium,
                height: iconSizeMedium,
                fit: BoxFit.cover,
              ),
            ),
            title: Text('English', style: Styles.popupText),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          // ListTile(
          //   leading: ClipRRect(
          //     borderRadius: BorderRadius.circular(borderRadiusSmallest),
          //     child: Image.asset(
          //       'assets/flags/dk.png',
          //       width: iconSizeMedium,
          //       height: iconSizeMedium,
          //       fit: BoxFit.cover,
          //     ),
          //   ),
          //   title: Text('Coming (postponed)', style: Styles.greyedOutPopupText),
          // ),
          // ListTile(
          //   leading: ClipRRect(
          //     borderRadius: BorderRadius.circular(borderRadiusSmall),
          //     child: Image.asset(
          //       'assets/flags/dk.png',
          //       width: iconSizeMedium,
          //       height: iconSizeMedium,
          //       fit: BoxFit.cover,
          //     ),
          //   ),
          //   title: Text('Coming (postponed)', style: Styles.greyedOutPopupText),
          // ), ListTile(
          //   leading: ClipRRect(
          //     borderRadius: BorderRadius.circular(borderRadiusSmall),
          //     child: Image.asset(
          //       'assets/flags/dk.png',
          //       width: iconSizeMedium,
          //       height: iconSizeMedium,
          //       fit: BoxFit.cover,
          //     ),
          //   ),
          //   title: Text('Coming (postponed)', style: Styles.greyedOutPopupText),
          // ), ListTile(
          //   leading: ClipRRect(
          //     borderRadius: BorderRadius.circular(borderRadiusSmall),
          //     child: Image.asset(
          //       'assets/flags/dk.png',
          //       width: iconSizeMedium,
          //       height: iconSizeMedium,
          //       fit: BoxFit.cover,
          //     ),
          //   ),
          //   title: Text('Coming (postponed)', style: Styles.greyedOutPopupText),
          // ),
        ],
      ),
    );
  }
}
