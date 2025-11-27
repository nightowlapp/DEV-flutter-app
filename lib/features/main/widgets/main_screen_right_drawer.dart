import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/features/main/widgets/utility/city_now_section_right_drawer.dart';
import 'package:nightowlcode/features/main/widgets/utility/favorites_section_right_drawer.dart';
import 'package:nightowlcode/features/main/widgets/utility/friends_section_right_drawer.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/users/language_switcher.dart';

import '../../../data/providers/users/profile_picture_provider.dart';
import '../../../shared/constants/enums.dart';
import '../../../shared/reusable/users/party_status_indicator.dart';
import '../../../shared/reusable/users/profile_picture_avatar.dart';
import '../../profile/presentation/change_profile_picture.dart';

class MainScreenRightDrawer extends StatelessWidget {
  const MainScreenRightDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final width = PlatformConfig.width(context) * 0.5;

    return Drawer(
      surfaceTintColor: owlPurple.withOpacity(0.01),
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: sidePaddingDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------- TOP ----------
              // Drawer snippet
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final hasPic =
                          ref.watch(hasCurrentUserProfilePictureProvider);

                      return ProfilePictureAvatar(
                        size: PlatformConfig.width(context) * 0.15,
                        useAuthUserAsFallback: true,

                        // Let the avatar show its prompt only when there is NO picture:
                        // (disablePrompt == true => no prompt)
                        disablePrompt:
                            hasPic, // hasPic -> no prompt; !hasPic -> prompt

                        // Only handle the "hasPic" case here; for !hasPic the avatar will prompt.
                        onTap: () async {
                          // close drawer first, then act
                          Scaffold.maybeOf(context)?.closeEndDrawer();

                          if (hasPic) {
                            context.goScreen(MainScreenName.profile);
                          }
                          // else do nothing here: avatar's _handleTap will open the upload popup
                        },
                      );
                    },
                  )
                ],
              ),

              const SizedBox(height: verticalSpacerMedium),

              const Align(
                alignment: Alignment.centerRight,
                child: PartyStatusIndicator(),
              ),

              const Divider(color: owlPurple),
              const SizedBox(height: verticalSpacerSmall),

              const FavoritesSectionRightDrawer(),

              const SizedBox(height: verticalSpacerSmall),
              const Divider(color: owlPurple),
              const SizedBox(height: verticalSpacerSmall),

              const FriendsSectionRightDrawer(),

              const SizedBox(height: verticalSpacerSmall),
              const Divider(color: owlPurple),
              const SizedBox(height: verticalSpacerSmall),

              // const SocialMedias(), // TODO Discord server. Other?
              // const CityNowSectionRightDrawer(), TODO after events are made.
            ],
          ),
        ),
      ),
    );
  }
}
