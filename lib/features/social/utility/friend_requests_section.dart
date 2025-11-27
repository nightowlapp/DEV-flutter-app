import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/providers/party_status/party_status_provider.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/reusable/ui/loading/error_screen.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

import '../../../data/providers/users/friends/friend_request_provider.dart';
import '../../../data/providers/users/user_providers.dart';
import '../../../models/users/friend_request.dart';

class FriendRequestsSection extends ConsumerWidget {
  const FriendRequestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(incomingFriendRequestsProvider);
final incomingCount = incoming.maybeWhen(
  data: (list) => list.length,
  orElse: () => 0,
);

    return incoming.when(
      loading: () => const SizedBox.shrink(), // keep this simple for now
      error: (e, st) {
        // 👇 This is the important part
        debugPrint('incomingFriendRequestsProvider error: $e');
        debugPrintStack(stackTrace: st);
        return const SizedBox.shrink();
      },
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
            Text('Friend Requests', style: Styles.basicTextHeader),
Spacer(),
Text(incomingCount.toString(), style: Styles.basicText,)
              ],
            ),
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
    final userAv = ref.watch(userByUidProvider(req.fromUid));

    return userAv.when(
      loading: () => const LoadingIndicator(),
      error: (_, __) => const ErrorScreen(),
      data: (u) {
        if (u == null) {
          return const SizedBox.shrink();
        }

        // Username (top line) and real name (second line, optional)
        final userName =
            Utility.formatString(u.userName); // e.g. @Magnompower style
        final fullName = (u.displayFullName).trim();

        final borderColor =
            ref.read(partyStatusColorForProvider(u.currentPartyStatus));

    return InkWell(
  borderRadius: BorderRadius.circular(10),
  onTap: () {
    context.pushNamedPage(
      'otherProfile',
      extra: u.id,
    );
  },
  child: AnimatedContainer(
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
        ProfilePictureAvatar(
          imageUrl: u.profilePictureUrl,
          borderColor: borderColor,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                userName,
                maxLines: 1,
              ),
              if (fullName.isNotEmpty) ...[
                const SizedBox(height: 2),
                AutoSizeText(
                  Utility.formatString(fullName),
                  maxLines: 1,
                  style: Styles.smallText,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                Utility.formatTimeAgo(req.createdAt),
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
  ),
);
  },
    );
  }
}
