
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';

import '../../../data/providers/party_status/party_status_provider.dart';
import '../../../data/providers/users/sorted_friends_provider.dart';
import '../../../shared/constants/colors.dart';
import '../utility/find_friends.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SocialScreen();

}
class _SocialScreen extends ConsumerState<SocialScreen> {

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(sortedFriendsProvider);
    // final partyStatusColor = ref.watch(partyStatusColorForProvider);
    final h = PlatformConfig.height(context);
    final w = PlatformConfig.width(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05),
          child: Column(
            children: [
              SizedBox(height: h * 0.01,),

              if (friends.length > 1)...[ //TODO make to MyFriends();

              Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Text('My Friends', style: Styles.basicTextHeader,),
                ]),

              SizedBox(height: h * 0.02,),

                SizedBox(
                  height: h * 0.12,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: friends.length, // amount of friends
                    separatorBuilder: (_, __) => SizedBox(width: w * 0.03),
                    itemBuilder: (context, index) {
                      final f = friends[index];

                      return GestureDetector(
                        // onTap: () => _openOtherProfile(context, f), // go to profile
                        // onLongPress: () => _openMap(context, f), // long tap -> map
                        child: ProfilePictureAvatar(
                          size: w * 0.20,
                          showOnlyInitials: true,
                          // imageProvider: f.avatar,
                          // borderColor:partyStatusColor
                        ),
                      );
                    },
                  ),
                ),
              // IF no friends:
              //           FIND FRIENDS SECTION instead of freinds. otherwise just find firends.
              Divider(color: white,),

                SizedBox(height: h * 0.02,),

              ],

              const FindFriends(),

            ],
          )
        ),
      )
    );
  }

}
