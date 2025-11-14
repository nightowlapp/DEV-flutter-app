import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/providers/party_status/party_status_provider.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

import '../../../data/providers/users/friends/friend_request_provider.dart';
import '../../../data/providers/users/user_providers.dart'; // <-- userByUidProvider here
import '../../../models/users/friend_request.dart';

class FriendRequestsSection extends ConsumerWidget {
  const FriendRequestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(incomingFriendRequestsProvider);

    return incoming.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Friend Requests', style: Styles.basicTextHeader),
            const SizedBox(height: 8),
            for (final req in list) _RequestRow(req: req),
          ],
        );
      },
    );
  }
}

class _RequestRow extends ConsumerWidget {
  const _RequestRow({required this.req, super.key});
  final FriendRequest req;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(friendRequestsRepositoryProvider);
    final userAv = ref.watch(userByUidProvider(req.fromUid)); // full user

    return userAv.when(
      loading: () => const LoadingIndicator(),
      error: (_, __) => const LoadingIndicator(),
      data: (u) {
        final displayName = (u?.displayFullName.isNotEmpty ?? false)
            ? Utility.formatString(u!.displayFullName)
            : (u?.userName.isNotEmpty ?? false)
                ? Utility.formatString(u!.userName)
                : 'Unknown user';

        final borderColor = u != null
            ? ref.watch(partyStatusColorForProvider(u.currentPartyStatus))
            : white;

        final avatar = (u?.profilePictureUrl?.isNotEmpty ?? false)
            ? ProfilePictureAvatar(
                imageUrl: u!.profilePictureUrl!,
                borderColor: borderColor,
              )
            : const SizedBox.shrink();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: black,
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      displayName,
                      maxLines: 1,
                      style: Styles.usernameDisplay,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Utility.formatTimeAgo(req.timestamp),
                      style: Styles.smallText,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(closeIcon, color: red),
                onPressed: () => repo.reject(req),
                tooltip: 'Reject',
              ),
              IconButton(
                icon: Icon(checkIcon, color: green),
                onPressed: () => repo.approve(req),
                tooltip: 'Approve',
              ),
            ],
          ),
        );
      },
    );
  }
}
