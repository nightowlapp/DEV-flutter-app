// lib/features/main/right_drawer/sections/friends_section_right_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightowlcode/data/providers/users/friends/active_friends_count_provider.dart';
import 'package:nightowlcode/data/providers/users/friends/sorted_friends_provider.dart';
import 'package:nightowlcode/data/providers/party_status/party_status_provider.dart';
import 'package:nightowlcode/data/providers/users/user_providers.dart';

import 'package:nightowlcode/models/users/user.dart' as model;

import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';

class FriendsSectionRightDrawer extends ConsumerWidget {
  const FriendsSectionRightDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(sortedFriendsProvider); // already sorted
    final activeCount = ref.watch(activeFriendsCountProvider);
    final totalCount = friends.length;

    final currentText = '$activeCount';
    final limitText = '$totalCount';
    final Color brand = owlPurple;
    final Color currentColor =
        activeCount <= friends.length / 2.floor() ? red : brand;
    final Color limitColor = brand;

    if (totalCount == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Text('Friends', style: Styles.boldText)),
          const SizedBox(height: verticalSpacerSmall),
          Center(
            child: Text(
              'No friends yet',
              style: Styles.smallText.copyWith(color: red),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Center(
              child: Text(
                'Friends',
                style: Styles.boldText,
              ),
            ),
            Positioned(
              right: 0,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: currentText,
                      style: Styles.basicText.copyWith(
                        color: currentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: ' / ',
                      style: Styles.basicText.copyWith(color: white),
                    ),
                    TextSpan(
                      text: limitText,
                      style: Styles.basicText.copyWith(
                        color: limitColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: verticalSpacerSmall),
        SizedBox(
          height: 50,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(friends.length, (i) {
                final user = friends[i]; // left → right in sorted order
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: horizontalSpacerSmall / 2,
                  ),
                  child: _FriendAvatar(uid: user.id),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendAvatar extends ConsumerWidget {
  const _FriendAvatar({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAv = ref.watch(userByUidProvider(uid));

    return userAv.when(
      loading: () => const LoadingIndicator(),
      error: (_, __) => const LoadingIndicator(),
      data: (u) {
        if (u == null) {
          return const SizedBox(
            width: circleAvatarSizeDefault * 2,
            height: circleAvatarSizeDefault * 2,
          );
        }

        final borderColor =
            ref.read(partyStatusColorForProvider(u.currentPartyStatus));

        final imageUrl = (u.profilePictureUrl?.isNotEmpty ?? false)
            ? u.profilePictureUrl!
            : null;

        return ProfilePictureAvatar(
          size: circleAvatarSizeDefault * 2,
          imageUrl: imageUrl,
          backgroundColor: borderColor,
        );
      },
    );
  }
}
