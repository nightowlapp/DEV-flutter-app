// lib/features/.../my_friends_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightowlcode/data/providers/users/friends/active_friends_count_provider.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';

import '../../../core/platform_config.dart';
import '../../../data/providers/users/friends/sorted_friends_provider.dart';
import '../../../data/providers/party_status/party_status_provider.dart';
import '../../../data/providers/users/user_providers.dart';
import 'package:nightowlcode/shared/party_priority.dart'; // 👈 add this

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
    final friendsRaw = ref.watch(sortedFriendsProvider);

    // turn into list of UIDs
    final friendIds =
        friendsRaw.map(_friendUidOf).where((id) => id.isNotEmpty).toList();

    if (friendIds.isEmpty) return const SizedBox.shrink();

    // 🔽 sort by partyPriority (lower = more to the left)
    friendIds.sort((a, b) {
      final aUser = ref.watch(userByUidProvider(a)).asData?.value;
      final bUser = ref.watch(userByUidProvider(b)).asData?.value;

      final pa = aUser != null ? partyPriority(aUser.currentPartyStatus) : 999;
      final pb = bUser != null ? partyPriority(bUser.currentPartyStatus) : 999;
      if (pa != pb) return pa.compareTo(pb);

      // tie-breaker: username
      final an = (aUser?.userName ?? '').toLowerCase();
      final bn = (bUser?.userName ?? '').toLowerCase();
      return an.compareTo(bn);
    });

    final activeCount = ref.watch(activeFriendsCountProvider);

    final h = PlatformConfig.height(context);
    final w = PlatformConfig.width(context);

    final currentText = '$activeCount';
    final limitText = '${friendIds.length}';
    final Color brand = owlPurple;
    final Color currentColor =
        activeCount <= friendIds.length ~/ 2 ? red : brand;
    final Color limitColor = brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: h * 0.01),
        Stack(
          children: [
            Text('My Friends', style: Styles.basicTextHeader),
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
        SizedBox(height: h * 0.01),
        SizedBox(
          // slightly taller to fit avatar + username
          height: h * 0.14,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: friendIds.length,
            separatorBuilder: (_, __) => SizedBox(width: w * 0.03),
            itemBuilder: (context, index) {
              final uid = friendIds[index];
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
        if (u == null) return const SizedBox.shrink();

        final borderColor =
            ref.read(partyStatusColorForProvider(u.currentPartyStatus));

        final imageUrl = (u.profilePictureUrl?.isNotEmpty ?? false)
            ? u.profilePictureUrl!
            : null;

        final displayName = u.userName.isNotEmpty
            ? u.userName
            : (u.displayFullName.isNotEmpty ? u.displayFullName : 'Friend');

        void _openProfile() {
          if (onTap != null) {
            onTap!(uid);
          } else {
            context.pushNamedPage('otherProfile', extra: uid);
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfilePictureAvatar(
              size: 66,
              imageUrl: imageUrl,
              backgroundColor: borderColor,
              borderColor: borderColor,
              onTap: _openProfile,
              onLongPress: onLongPress == null ? null : () => onLongPress!(uid),
              semanticLabel: displayName,
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 70,
              child: GestureDetector(
                onTap: _openProfile,
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Styles.smallText.copyWith(color: blue),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
