import 'package:flutter/material.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/features/main/widgets/utility/city_now_section_right_drawer.dart';
import 'package:nightowlcode/features/main/widgets/utility/favorites_section_right_drawer.dart';
import 'package:nightowlcode/features/main/widgets/utility/friends_section_right_drawer.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/users/language_switcher.dart';

import '../../../shared/constants/enums.dart';
import '../../../shared/reusable/users/party_status_indicator.dart';
import '../../../shared/reusable/users/profile_picture_avatar.dart';


class MainScreenLeftDrawer extends StatelessWidget {
  const MainScreenLeftDrawer({super.key});

  //TODO ADD Refer a friend
  // Row(children: [Text("QR code to add profile as friend?")],), TODO QR To add this profile as friend?

  @override
  Widget build(BuildContext context) {
    final width = PlatformConfig.width(context) * 0.5;

    return Drawer(
      surfaceTintColor: owlOrange.withOpacity(0.01),
      shadowColor: grey,
      backgroundColor: black,
      width: width,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(300),
          bottomLeft: Radius.circular(300),
        ),
        side: BorderSide(color: grey, width: 0.7),
      ),
      child:  SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: sidePaddingDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------- TOP ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => context.goScreen(MainScreenName.profile), // <— typed, DRY
                    child: ProfilePictureAvatar(
                      imageUrl: 'assets/nightowl/logo.png',
                      size: PlatformConfig.width(context) * 0.15,
                      borderWidth: 2,
                      showStatus: true,
                      statusColor: Colors.green,
                      tooltip: 'My Profile',
                      heroTag: 'profile-avatar',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: verticalSpacerMedium),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PartyStatusIndicator(),
                  const LanguageSwitcher(),
                ],
              ),

              const SizedBox(height: verticalSpacerSmall),
              const Divider(color: owlOrange),
              const SizedBox(height: verticalSpacerSmall),

              const FavoritesSectionRightDrawer(),

              const SizedBox(height: verticalSpacerSmall),
              const Divider(color: owlOrange),
              const SizedBox(height: verticalSpacerSmall),

              const FriendsSectionRightDrawer(),

              const SizedBox(height: verticalSpacerSmall),
              const Divider(color: owlOrange),
              const SizedBox(height: verticalSpacerSmall),

              const CityNowSectionRightDrawer(),
            ],
          ),
        ),
      ),
    );
  }
}


