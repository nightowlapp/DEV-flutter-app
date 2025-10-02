
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/features/social/utility/find_friends_section.dart';
import 'package:nightowlcode/features/social/utility/friend_request_section.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';

import '../../../data/providers/party_status/party_status_provider.dart';
import '../../../data/providers/users/sorted_friends_provider.dart';
import '../../../shared/constants/colors.dart';
import '../utility/my_friends_section.dart';

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
    final bool newRequests = false;

    return Scaffold(body: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: h * 0.01),

// const FriendRequestsSection(),

            // ✅ New reusable section
            MyFriendsSection(
              onTapFriend: (f) {
                // TODO: open profile
              },
              onLongPressFriend: (f) {
                // TODO: open map and focus on friend
              },
            ),

            // IF no friends:
              //           FIND FRIENDS SECTION instead of freinds. otherwise just find firends.
              const Divider(color: white,),

              SizedBox(height: h * 0.02,),


            const FindFriendsSection(),
          ],

        )
      ),
    );
  }

}
