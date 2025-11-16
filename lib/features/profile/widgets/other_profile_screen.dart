import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';
import 'package:nightowlcode/core/platform_config.dart';

import 'package:nightowlcode/data/providers/users/user_providers.dart';
import 'package:nightowlcode/data/providers/party_status/party_status_provider.dart';

class OtherProfileScreen extends ConsumerWidget {
  const OtherProfileScreen({
    super.key,
    required this.uid,
  });

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAv = ref.watch(userByUidProvider(uid));

    return userAv.when(
      loading: () => const Scaffold(
        backgroundColor: black,
        body: Center(child: CircularProgressIndicator(color: owlPurple)),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: black,
        body: Center(child: Text('Error loading profile', style: Styles.basicText)),
      ),
      data: (u) {
        if (u == null) {
          return Scaffold(
            backgroundColor: black,
            body: Center(child: Text('User not found', style: Styles.basicText)),
          );
        }

        final borderColor =
            ref.read(partyStatusColorForProvider(u.currentPartyStatus));

        final avatarSize = PlatformConfig.width(context) * 0.15;

        return Scaffold(
          backgroundColor: black,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(sidePaddingDefault),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + username (live)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.displayFullName.isNotEmpty
                            ? u.displayFullName
                            : u.userName,
                        style: const TextStyle(
                          color: white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        u.userName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: greyLighter,
                        ),
                      ),
                    ],
                  ),

                  // Avatar with status ring
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: ProfilePictureAvatar(
                      imageUrl: u.profilePictureUrl,
                      size: avatarSize,
                      backgroundColor: borderColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
