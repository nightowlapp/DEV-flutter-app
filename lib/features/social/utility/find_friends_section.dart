import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';
import 'package:nightowlcode/shared/constants/icons.dart';

import '../../../data/providers/users/find_friends_providers.dart'; // 👈 NEW
import '../../../data/providers/users/friend_request_provider.dart';
import '../../../data/repositories/users/friend_requests_repository.dart';
import '../../../models/users/user.dart' as model;

// ... (rest unchanged)

class _UserRow extends ConsumerWidget {
  const _UserRow({required this.user, required this.avatarSize});
  final model.User user;
  final double avatarSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(friendRequestsRepositoryProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: white, width: 1),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: ProfilePictureAvatar(
            size: avatarSize,
            showOnlyInitials: true,
            imageProvider: user.hasProfilePicture
                ? NetworkImage(user.profilePictureUrl!)
                : null,
          ),
          title: Text(
            user.userName.isNotEmpty ? user.userName : user.displayFullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: white, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${user.userName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          trailing: IconButton(
            tooltip: 'Add friend',
            icon: const Icon(Icons.person_add_alt_1_outlined, color: owlPurple),
            onPressed: () async {
              await repo.send(toUid: user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Friend request sent to @${user.userName}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          onTap: () {
            // TODO: navigate to profile
          },
        ),
      ),
    );
  }
}
