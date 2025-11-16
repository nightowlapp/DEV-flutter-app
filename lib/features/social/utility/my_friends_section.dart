// lib/features/.../my_friends_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightowlcode/data/providers/users/friends/active_friends_count_provider.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';

import '../../../core/platform_config.dart';
import '../../../data/providers/users/sorted_friends_provider.dart';
import '../../../data/providers/party_status/party_status_provider.dart';
import '../../../data/providers/users/user_providers.dart';

class MyFriendsSection extends ConsumerWidget {
  const MyFriendsSection({
    super.key,
    this.onTapFriend,
    this.onLongPressFriend,
  });

  final void Function(String uid)? onTapFriend;
  final void Function(String uid)? onLongPressFriend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(sortedFriendsProvider);
    if (friends.isEmpty) return const SizedBox.shrink();

    final activeCount = ref.watch(activeFriendsCountProvider);

    final h = PlatformConfig.height(context);
    final w = PlatformConfig.width(context);

    final currentText = '$activeCount';
    final limitText = '${friends.length}';
    final Color brand = owlPurple;
    final Color currentColor = activeCount <= friends.length/2.floor() ? red : brand;
    final Color limitColor = brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: h * 0.01),
        Stack(
          children: [
            Center(
              child: Text('My Friends', style: Styles.basicTextHeader),
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
                      style: Styles.basicText,
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
        SizedBox(height: h * 0.02),
        SizedBox(
          height: h * 0.1,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: friends.length,
            separatorBuilder: (_, __) => SizedBox(width: w * 0.03),
            itemBuilder: (context, index) {
              final uid = _friendUidOf(friends[index]);
              if (uid.isEmpty) {
                return const SizedBox.shrink();
              }
              return _FriendAvatar(
                uid: uid,
                onTap: onTapFriend,
                onLongPress: onLongPressFriend,
              );
            },
          ),
        ),
      ],
    );
  }

  String _friendUidOf(dynamic f) {
    if (f is String) return f;
    try {
      final uid = (f as dynamic).uid as String?;
      if (uid != null && uid.isNotEmpty) return uid;
    } catch (_) {}
    try {
      final id = (f as dynamic).id as String?;
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    return '';
  }
}

class _FriendAvatar extends ConsumerWidget {
  const _FriendAvatar({
    required this.uid,
    this.onTap,
    this.onLongPress,
  });

  final String uid;
  final void Function(String uid)? onTap;
  final void Function(String uid)? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAv = ref.watch(userByUidProvider(uid));

    return userAv.when(
      loading: () => const LoadingIndicator(),
      error: (_, __) => const LoadingIndicator(),
      data: (u) {
        if (u == null) {
          return const SizedBox.shrink();
        }

        final borderColor =
            ref.read(partyStatusColorForProvider(u.currentPartyStatus));

        final imageUrl = (u.profilePictureUrl?.isNotEmpty ?? false)
            ? u.profilePictureUrl!
            : null;

        final avatar = Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
              ),
              child: ProfilePictureAvatar(
                size: 66,
                imageUrl: imageUrl,
                backgroundColor: borderColor,
              ),
            ),
          ],
        );

        return GestureDetector(
          onTap: onTap == null ? null : () => onTap!(uid),
          onLongPress: onLongPress == null ? null : () => onLongPress!(uid),
          child: Semantics(
            label: u.displayFullName?.isNotEmpty == true
                ? u.displayFullName
                : (u.userName?.isNotEmpty == true ? u.userName : 'Friend'),
            child: avatar,
          ),
        );
      },
    );
  }
}
