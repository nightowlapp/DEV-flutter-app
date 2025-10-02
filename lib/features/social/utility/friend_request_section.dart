// lib/features/social/widgets/friend_requests_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';

import '../../../data/providers/users/friend_request_provider.dart';
import '../../../models/users/friend_request.dart';


class FriendRequestsSection extends ConsumerWidget {
  const FriendRequestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(incomingFriendRequestsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: incoming.when(
          loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: owlPurple))),
          error: (e, _) => SizedBox(height: 120, child: Center(child: Text('Error: $e', style: Styles.smallText))),
          data: (list) {
            if (list.isEmpty) {
              return const SizedBox(height: 120, child: Center(child: Text('No friend requests', style: TextStyle(color: white))));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Friend Requests', style: Styles.boldText),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _RequestRow(req: list[i]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RequestRow extends ConsumerWidget {
  final FriendRequest req;
  const _RequestRow({required this.req});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(friendRequestsRepositoryProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: white, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // TODO: replace with requester's avatar (from /users/{fromUid})
          const ProfilePictureAvatar(size: 44, showOnlyInitials: true),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Request from ${req.fromUid}', style: const TextStyle(color: white, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Reject',
            icon: const Icon(Icons.close, color: red),
            onPressed: () => repo.reject(req),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: owlPurple, foregroundColor: white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => repo.approve(req),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
}
