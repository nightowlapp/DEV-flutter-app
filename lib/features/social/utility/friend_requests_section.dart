// lib/features/social/widgets/friend_requests_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import '../../../data/providers/users/friend_request_provider.dart';
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
  const _RequestRow({required this.req});
  final FriendRequest req;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(friendRequestsRepositoryProvider);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: white, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Request from ${req.fromUid}', style: Styles.basicText),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: red),
            onPressed: () => repo.reject(req),
            tooltip: 'Reject',
          ),
          const SizedBox(width: 6),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: owlPurple),
            onPressed: () => repo.approve(req),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
}
