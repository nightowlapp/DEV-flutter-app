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
import '../../../shared/constants/enums.dart';
import '../../../shared/constants/values.dart';

class FriendRequestsSection extends ConsumerWidget {
  const FriendRequestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingAv = ref.watch(incomingFriendRequestsProvider);
    final outgoingAv = ref.watch(outgoingFriendRequestsProvider);

    // log + collapse on error
    if (incomingAv.hasError) {
      debugPrint('incomingFriendRequestsProvider error: ${incomingAv.error}');
    }
    if (outgoingAv.hasError) {
      debugPrint('outgoingFriendRequestsProvider error: ${outgoingAv.error}');
    }
    if (incomingAv.hasError || outgoingAv.hasError) {
      return const SizedBox.shrink();
    }

    // you can show a skeleton instead if you like
    if (incomingAv.isLoading && outgoingAv.isLoading) {
      return const SizedBox.shrink();
    }

    final allIncoming = incomingAv.asData?.value ?? const <FriendRequest>[];
    final incoming =
      allIncoming.where((r) => r.statusIsPending).toList(growable: false);

    // existing outgoing logic
    final allOutgoing = outgoingAv.asData?.value ?? const <FriendRequest>[];
    final pendingOutgoing =
      allOutgoing.where((r) => r.statusIsPending).toList(growable: false);

    if (incoming.isEmpty && pendingOutgoing.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (incoming.isNotEmpty) ...[
          Row(
            children: [
              Text('Received Friend Requests',
                style: Styles.basicText.copyWith(color: greyLighter)
              ),
              const Spacer(),
              Text(
                '${incoming.length}',
                style: Styles.basicText.copyWith(color: greyLighter),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Incoming (requests sent TO me)
        if (incoming.isNotEmpty) ...[
          for (final req in incoming) _IncomingRequestRow(req: req),
        ],

        const SizedBox(height: 8),

        // Outgoing (requests I sent)
        if (pendingOutgoing.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Sent Friend Requests',
                style: Styles.basicText.copyWith(color: greyLighter),
              ),
              const Spacer(),
              Text(
                '${pendingOutgoing.length}',
                style: Styles.basicText.copyWith(color: greyLighter),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final req in pendingOutgoing) _OutgoingRequestRow(req: req),
        ],
      ],
    );
  }
}

// -------- Incoming row (someone sent a request TO me) ------------------------

class _IncomingRequestRow extends ConsumerWidget {
  const _IncomingRequestRow({required this.req, super.key});
  final FriendRequest req;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(friendRequestsRepositoryProvider);
    // incoming => show the *sender*
    final userAv = ref.watch(userByUidProvider(req.fromUid));

    return userAv.when(
      loading: () => const LoadingIndicator(),
      error: (_, __) => const ErrorScreen(),
      data: (u) {
        if (u == null) return const SizedBox.shrink();

        final userName = Utility.formatString(u.userName);
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
                  onTap: () {
                    context.pushNamedPage(
                      'otherProfile',
                      extra: u.id,
                    );
                  },
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(userName, maxLines: 1),
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
                        Utility.formatString(
                          Utility.formatTimeAgo(req.createdAt)),
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

// -------- Outgoing row (I sent a request TO them) ---------------------------

class _OutgoingRequestRow extends ConsumerWidget {
  const _OutgoingRequestRow({required this.req, super.key});
  final FriendRequest req;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(friendRequestsRepositoryProvider);
    final userAv = ref.watch(userByUidProvider(req.toUid));

    return userAv.when(
      loading: () => const LoadingIndicator(),
      error: (_, __) => const ErrorScreen(),
      data: (u) {
        if (u == null) return const SizedBox.shrink();

        final userName = Utility.formatString(u.userName);
        final fullName = (u.displayFullName).trim();
        final borderColor =
          ref.read(partyStatusColorForProvider(u.currentPartyStatus));

        return InkWell(
          borderRadius: BorderRadius.circular(borderRadiusDefault),
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
              borderRadius: BorderRadius.circular(borderRadiusDefault),
            ),
            child: Row(
              children: [
                ProfilePictureAvatar(
                  imageUrl: u.profilePictureUrl,
                  borderColor: borderColor,
                  onTap: () {
                    context.pushNamedPage(
                      'otherProfile',
                      extra: u.id,
                    );
                  },
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(userName, maxLines: 1),
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
                        'Sent ${Utility.formatString(Utility.formatTimeAgo(req.createdAt))}',
                        style: Styles.smallText,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(closeIcon, color: red),
                  tooltip: 'Cancel request',
                  onPressed: () async {
                    await repo.cancelOutgoing(req);
                    // Stream will update automatically; no extra UI handling needed
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---- tiny extension so we can check status without exposing enums here -----

extension FriendRequestX on FriendRequest {
  bool get statusIsPending => status == FriendRequestStatus.pending;
}
