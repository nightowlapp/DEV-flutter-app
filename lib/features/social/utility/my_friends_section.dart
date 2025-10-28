// lib/features/social/widgets/my_friends_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';

import '../../../core/platform_config.dart';
import '../../../shared/constants/enums.dart';
import '../../../data/providers/users/sorted_friends_provider.dart';
import '../../../data/providers/party_status/party_status_provider.dart';

class MyFriendsSection extends ConsumerWidget {
  const MyFriendsSection({
    super.key,
    this.onTapFriend,
    this.onLongPressFriend,
  });

  final void Function(dynamic friend)? onTapFriend;
  final void Function(dynamic friend)? onLongPressFriend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(sortedFriendsProvider);
    if (friends.isEmpty) return const SizedBox.shrink();

    int active = 0;
    for (final f in friends) {
      final uid = _friendUidOf(f);
      final status = ref.watch(partyStatusForUserProvider(uid)).maybeWhen(
        data: (s) => s,
        orElse: () => PartyStatusTypes.still_planning,
      );
      if (status != PartyStatusTypes.still_planning &&
          status != PartyStatusTypes.recovering) {
        active++;
      }
    }

    final h = PlatformConfig.height(context);
    final w = PlatformConfig.width(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: h * 0.01),
        Row(
          children: [
            Text('My Friends', style: Styles.basicTextHeader),
            const Spacer(),
            Text('$active/${friends.length}', style: Styles.smallText),
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
              final f = friends[index];
              return ProfilePictureAvatar(
                // Provide callbacks if you like:
                // onTap: () => onTapFriend?.call(f),
                // onLongPress: () => onLongPressFriend?.call(f),
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
