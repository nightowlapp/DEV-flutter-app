import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

import '../../../core/platform_config.dart';
import '../../../shared/constants/values.dart';
import '../../../shared/reusable/users/profile_picture_avatar.dart';

class FriendProfileScreen extends ConsumerStatefulWidget {
  const FriendProfileScreen({super.key});
  @override
  ConsumerState<FriendProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<FriendProfileScreen> {@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(sidePaddingDefault),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full name and username
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const[
                  Text(
                    'Poul Magne Skov',
                    style: TextStyle(
                      color: white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Magnompower',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              // Avatar
              ProfilePictureAvatar( //TODO Friend
                imageUrl: 'assets/nightowl/test.png',
                size: PlatformConfig.width(context) * 0.15,
                borderWidth: 2,
                tooltip: 'My Profile',
                heroTag: 'profile-avatar',
              ),
            ],
          ),
        ),
      ),
    );
  }


}
