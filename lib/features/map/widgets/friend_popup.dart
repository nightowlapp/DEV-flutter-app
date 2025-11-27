import 'package:flutter/material.dart';
import 'package:nightowlcode/models/users/friend.dart';
import 'package:nightowlcode/models/users/live_location.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

String _formatStatusDurationFrom(DateTime since) {
  final d = DateTime.now().difference(since);

  if (d.inMinutes < 1) return 'less than a minute';
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  if (d.inHours < 24) return '${d.inHours} h';

  final days = d.inDays;
  return '$days day${days == 1 ? '' : 's'}';
}

String _formatPartyStatus(String? rawStatus) {
  final status = rawStatus ?? 'still_planning';

  switch (status) {
  // TODO mappings you wanted
    case 'out_tonight':
      return 'Out';
    case 'pregame':
      return 'Pregaming';
    case 'house_party':
      return 'House partying';
    case 'still_planning':
      return 'Planning';
    case 'recovering':
      return 'Recovering';
    default:
      return Utility.formatString(status.replaceAll('_', ' ')) ?? status;
  }
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
    final lastActiveAgo =
    Utility.formatString(Utility.formatTimeAgo(loc.timestamp));

    // Pretty party status
    final prettyStatus = _formatPartyStatus(profile.partyStatus?.name);

    // "been partyStatus for XXXX time"
    final statusFor = _formatStatusDurationFrom(
      loc.timestamp,
    ); // todo find und users/id/party_status_days/todayOrYesterday/entries/entryid/created_at

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: blue),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProfilePictureAvatar(
                    // imageUrl: friend.url
                  ),
                  const SizedBox(width: 6),

                  // Name + Active + Been status + Close X
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: name + "Active ..."
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: Styles.usernameDisplay,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Active $lastActiveAgo',
                                style: Styles.smallText.copyWith(
                                  color: greyLighter,
                                ),
                              ),
                            ],
                          ),
                        ),


                        // Right side: X above "Been ... for ..."
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Been $prettyStatus for $statusFor',
                              style: Styles.smallText.copyWith(
                                color: greyLighter,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(closeIcon,
                          color: greyLighter, size: iconSizeDefault),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // TODO invite to venue - venue + day time?
              // TODO "profile"
              // TODO message
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
