import 'dart:math' as math;

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
              // TODO last visits - timestamp
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


class FriendMapBubble extends StatelessWidget {
  final String uid;
  final FriendProfile profile;
  final LiveLocation loc;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onMessage;
  final VoidCallback? onClose;

  const FriendMapBubble({
    super.key,
    required this.uid,
    required this.profile,
    required this.loc,
    this.onOpenProfile,
    this.onMessage,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile.displayName?.isNotEmpty == true
        ? profile.displayName!
        : uid;

    final rawStatus = profile.partyStatus?.name ?? 'still_planning';
    final prettyStatus = Utility.formatString(
      rawStatus.replaceAll('_', ' '),
    ) ??
        rawStatus;

    // For now we reuse the location timestamp for the “been XYZ for …”
    final prettyTime = Utility.formatTimeAgo(loc.timestamp);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ===== bubble =====
        Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: Styles.basicText,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Active $prettyStatus',
                      style: Styles.smallText,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Been $prettyStatus for $prettyTime',
                      style: Styles.smallText.copyWith(color: greyLighter),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                if (onMessage != null)
                  IconButton(
                    icon: const Icon(Icons.message, size: 18, color: white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onMessage,
                  ),
                if (onOpenProfile != null)
                  IconButton(
                    icon: const Icon(Icons.person, size: 18, color: white),
                    padding: const EdgeInsets.only(left: 4),
                    constraints: const BoxConstraints(),
                    onPressed: onOpenProfile,
                  ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                    padding: const EdgeInsets.only(left: 4),
                    constraints: const BoxConstraints(),
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
        ),
        // ===== small arrow pointing to marker =====
        Transform.rotate(
          angle: math.pi, // upside-down arrow_drop_up → arrow pointing down
          child: const Icon(
            Icons.arrow_drop_up,
            size: 20,
            color: black,
          ),
        ),
      ],
    );
  }
}