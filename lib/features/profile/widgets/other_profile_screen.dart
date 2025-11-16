// lib/features/profile/widgets/other_profile_screen.dart
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/providers/favorite_venues/favorite_venues_provider.dart';
import 'package:nightowlcode/data/providers/users/friends/friend_request_provider.dart';
import 'package:nightowlcode/data/providers/users/friends/friends_provider.dart';
import 'package:nightowlcode/data/repositories/users/friend_requests_repository.dart';

import 'package:nightowlcode/features/main/widgets/main_app_bar.dart';
import 'package:nightowlcode/features/signup/widgets/favorite_venues_section.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/reusable/ui/venue_logo.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';
import 'package:nightowlcode/shared/reusable/users/party_status_indicator.dart'; // only if you want same widget
import 'package:nightowlcode/shared/utility/level_logic.dart';

import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/data/providers/users/user_providers.dart';
import 'package:nightowlcode/data/providers/party_status/party_status_provider.dart';

import 'emblems_section.dart';
import 'level_indicator.dart';
import 'visits_section.dart';

class OtherProfileScreen extends ConsumerWidget {
  const OtherProfileScreen({
    super.key,
    required this.uid,
  });

  final String uid;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAv = ref.watch(userByUidProvider(uid));

    return userAv.when(
      loading: () => const Scaffold(
        backgroundColor: black,
        body: SafeArea(
          child: Center(child: LoadingIndicator()),
        ),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: black,
        body: SafeArea(
          child: Center(
            child: Text('Error loading profile', style: Styles.basicText),
          ),
        ),
      ),
      data: (u) {
        if (u == null) {
          return Scaffold(
            backgroundColor: black,
            body: SafeArea(
              child: Center(
                child: Text('User not found', style: Styles.basicText),
              ),
            ),
          );
        }

        // ---- Level / XP logic (same as MyProfileScreen, but for this user) ----
        final totalXp = u.xp.toDouble();
        final p = LevelLogic.progress(totalXp);

        final xpThisLevel = LevelLogic.calculateThisLevelTotalXp(
          currentXp: totalXp,
          currentLevel: p.level,
        );
        final currentXp = LevelLogic.calculateUserXpThisLevel(
          currentXp: totalXp,
          currentLevel: p.level,
        );

        final borderColor =
            ref.read(partyStatusColorForProvider(u.currentPartyStatus));

  // Are we already friends with this user?
  final friendsAv = ref.watch(friendsProvider);
  final isFriend = friendsAv.maybeWhen(
    data: (list) => list.any((f) => f.id == u.id),
    orElse: () => false,
  );

        return Scaffold(
          backgroundColor: black,
          appBar: const MainAppBar(
            showBack: true,
            centerTitle: true,
            action: SizedBox.shrink(),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- TOP ROW: avatar + names + status ----------
            // ---------- TOP ROW: avatar + names + friend status ----------
Row(
  children: [
    // LEFT: avatar + names
    Expanded(
      child: SizedBox(
        height: PlatformConfig.height(context) * 0.12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Other user's avatar (NO edit prompt)
            ProfilePictureAvatar(
              size: PlatformConfig.width(context) * 0.25,
              imageUrl: u.profilePictureUrl,
              backgroundColor: borderColor,
              disablePrompt: true, // don't let you change *their* picture
            ),
            const SizedBox(width: horizontalSpacerMedium),

            // Names
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full name
                  AutoSizeText(
                    u.displayFullName.isNotEmpty
                        ? u.displayFullName
                        : u.userName,
                    maxLines: 1,
                  ),
                  const SizedBox(height: verticalSpacerVerySmall),
                  // Username
                  AutoSizeText(
                    u.userName,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),

    // RIGHT: friend icon (far right)
    SizedBox(
      width: 44,
      child: Align(
        alignment: Alignment.centerRight,
        child: isFriend
            ? Icon(
                profileIcon,
                color: green,
                size: 26,
              )
            : IconButton( // TODO make best friend a possibility. Just simple
                icon: Icon(
                  Icons.person_add_alt_1_outlined,
                  color: owlPurple,
                  size: 24,
                ),
                tooltip: 'Add friend',
                onPressed: () async {
                  final repo = ref.read(friendRequestsRepositoryProvider);
                  final res = await repo.send(toUid: u.id);

                  final (msg, ok) = _msgForResult(res, u.userName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor:
                          ok ? green : red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
      ),
    ),
  ],
),

 const SizedBox(height: verticalSpacerDefault),

                  // ---------- LEVEL INDICATOR (same style) ----------
                  LevelIndicator(
                    levelLabel: u.level.toInt() == 1337
                        ? 'Level 1337'
                        : 'Level ${p.level.toInt()}',
                    current: u.level.toInt() == 1337
                        ? 69
                        : currentXp.toInt(),
                    total: u.level.toInt() == 1337
                        ? 420
                        : xpThisLevel.toInt(),
                    height: PlatformConfig.height(context) * 0.05,
                    gradient: const LinearGradient(
                      colors: [owlPurple, purple, owlPurple, purple],
                    ),
                    trackColor: grey,
                  ),

                  const SizedBox(height: verticalSpacerDefault),

                  // ---------- EMblems / Achievements ----------
                  const EmblemsSection(achieved: 37, total: 113, title: 'Emblems',),



_OtherUserFavoritesSection(uid: u.id), // TODO Show x / X as in other places.

                 if(isFriend)
                  const Expanded(
                    child: VisitsSection(
                      maxHeight: null,
                      title: 'Visits',
                      seeAllEnabled: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
// make sure this import is at the top

(String, bool) _msgForResult(FriendRequestSendResult r, String name) {
  switch (r) {
    case FriendRequestSendResult.sent:
      return ('Friend request sent to $name', true);
    case FriendRequestSendResult.notAuthenticated:
      return ('You need to sign in first.', false);
    case FriendRequestSendResult.selfRequest:
      return ('You cannot add yourself.', false);
    case FriendRequestSendResult.alreadyFriends:
      return ('You are already friends.', false);
    case FriendRequestSendResult.alreadyPending:
      return ('Request already pending.', false);
    case FriendRequestSendResult.error:
    default:
      return ('Could not send request. Try again.', false);
  }
}
}

class _OtherUserFavoritesSection extends ConsumerWidget {
  const _OtherUserFavoritesSection({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(favoriteVenuesForUserProvider(uid));

    // base the sizes on your logoIcon constant
    const double logoScale = 1.5;
    final double logoSize = logoIcon * logoScale;
    final double sectionHeight = logoSize + 28; // room for text + spacing

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: verticalSpacerDefault),
        Center(child: Text('Favorite Venues', style: Styles.basicText)),
        const SizedBox(height: verticalSpacerSmall),

        SizedBox(
          height: sectionHeight,
          child: venuesAsync.when(
            loading: () => const LoadingIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (venues) {
              if (venues.isEmpty) {
                return Center(
                  child: Text(
                    'No favorites',
                    style: Styles.smallText.copyWith(color: greyLighter),
                  ),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final v in venues)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: horizontalSpacerSmall,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VenueLogo(
                              venue: v,
                              size: logoSize,
                              shape: VenueLogoShape.circle,
                              showTypeIfNoLogo: true,
                              tooltip: v.displayName.isNotEmpty
                                  ? v.displayName
                                  : v.name,
                              // onTap: () async {
                              //   await context.goToMapAndFocusVenue(
                              //     ref,
                              //     v,
                              //     zoom: 16,
                              //   );
                              // },
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: logoSize, // keep names from stretching
                              child: AutoSizeText(
                                v.displayName.isNotEmpty
                                    ? v.displayName
                                    : v.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Styles.smallText,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
