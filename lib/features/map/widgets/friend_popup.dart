import 'package:flutter/material.dart';
import 'package:nightowlcode/models/users/friend.dart';
import 'package:nightowlcode/models/users/live_location.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

String _formatStatusDurationFrom(DateTime since) {
  final d = DateTime.now().difference(since);

  if (d.inMinutes < 1) return 'less than a minute';
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  if (d.inHours < 24) return '${d.inHours} h';

  final days = d.inDays;
  return '$days day${days == 1 ? '' : 's'}';
}

/// Helper: show the friend popup as a bottom sheet.
Future<void> showFriendPopupSheet(
    BuildContext context, {
      required String uid,
      required FriendProfile profile,
      required LiveLocation loc,
      VoidCallback? onMessage,
    }) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return FriendPopup(
        uid: uid,
        profile: profile,
        loc: loc,
        onMessage: onMessage == null
            ? null
            : () {
          onMessage();
          Navigator.of(ctx).pop();
        },
        onClose: () => Navigator.of(ctx).pop(),
      );
    },
  );
}

class FriendPopup extends StatelessWidget {
  final String uid;
  final FriendProfile profile;
  final LiveLocation loc;
  final VoidCallback? onMessage;
  final VoidCallback? onClose;

  const FriendPopup({
    super.key,
    required this.uid,
    required this.profile,
    required this.loc,
    this.onMessage,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile.displayName?.isNotEmpty == true
        ? profile.displayName!
        : uid;

    // "Active XXXX"
    final lastActiveAgo = Utility.formatTimeAgo(loc.timestamp);

    // Pretty party status
    final rawStatus = profile.partyStatus?.name ?? 'still_planning';
    final prettyStatus =
        Utility.formatString(rawStatus.replaceAll('_', ' ')) ?? rawStatus;

    // "been partyStatus for XXXX time"
    // (using loc.timestamp as "since" – if you have a dedicated
    //  partyStatusSince field, swap it in here)
    final statusFor = _formatStatusDurationFrom(loc.timestamp);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white10,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      profileIcon,
                      color: white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Styles.basicText,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // 👉 "Active XXXX"
                        Text(
                          'Active $lastActiveAgo',
                          style: Styles.smallText.copyWith(
                            color: greyLighter,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white70,
                    ),
                    onPressed: onClose,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Status + duration
              Text(
                'Status: $prettyStatus',
                style: Styles.smallText,
              ),
              const SizedBox(height: 4),
              Text(
                'Been $prettyStatus for $statusFor',
                style: Styles.smallText.copyWith(color: greyLighter),
              ),

              const SizedBox(height: 12),

              // Actions row
              // Row(
              //   children: [
              //     if (onMessage != null)
              //       TextButton.icon(
              //         onPressed: onMessage,
              //         icon: const Icon(Icons.message, size: 18),
              //         label: const Text('Message'),
              //       ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
