// lib/features/profile/widgets/my_profile_screen.dart (or similar)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/profile/presentation/change_profile_picture.dart';
import 'package:nightowlcode/features/profile/widgets/timeline_section.dart';
import 'package:nightowlcode/features/profile/widgets/visits_section.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/utility/level_logic.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../../../core/platform_config.dart';
import '../../../data/providers/other_providers.dart';
import '../../../data/providers/visits/visit_xp_provider.dart';
import '../../../models/users/user.dart';
import '../../../shared/constants/values.dart';
import '../../../shared/reusable/ui/buttons.dart';
import '../../../shared/reusable/users/party_status_indicator.dart';
import '../../../shared/reusable/users/profile_picture_avatar.dart';
import 'emblems_section.dart';
import 'level_indicator.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});
  @override
  ConsumerState<MyProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<MyProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final User? u = ref.watch(authUserProvider).valueOrNull;

    // Guard against null user (loading / signed-out)
    if (u == null) {
      return const Scaffold(
        backgroundColor: black,
        body: SafeArea(
          child: Center(child: LoadingIndicator()),
        ),
      );
    }

    // XP from all visit sessions
    final visitXp = ref.watch(myVisitXpProvider);

    // TOTAL XP that drives the level bar.
    // If you also use u.xp from Firestore, you can change this to:
    //   final totalXp = u.xp.toDouble() + visitXp.toDouble();
    final totalXp = visitXp.toDouble();

    final p = LevelLogic.progress(totalXp);

    final xpThisLevel = LevelLogic.calculateThisLevelTotalXp(
      currentXp: totalXp,
      currentLevel: p.level,
    );
    final currentXp = LevelLogic.calculateUserXpThisLevel(
      currentXp: totalXp,
      currentLevel: p.level,
    );

    return Scaffold(
      backgroundColor: black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // LEFT: avatar + names -> takes all remaining width
                  Expanded(
                    child: SizedBox(
                      height: PlatformConfig.height(context) * 0.12,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ProfilePictureAvatar(
                            size: PlatformConfig.width(context) * 0.25,
                            disablePrompt: false,
                            useAuthUserAsFallback: true,
                          ),
                          const SizedBox(width: horizontalSpacerMedium),

                          // names expand inside the left side
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  u.displayFullName,
                                  style: Styles.fullNameDisplay,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: verticalSpacerVerySmall),
                                Text(
                                  u.userName,
                                  style: Styles.usernameDisplay,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // RIGHT: keep a fixed (or small) width
                  SizedBox(
                    width: PlatformConfig.width(context) * 0.25,
                    height: PlatformConfig.height(context) * 0.12,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(height: PlatformConfig.height(context) * 0.01),
                        const SizedBox.shrink(),
                        SizedBox(
                          height: PlatformConfig.height(context) * 0.03,
                          child: const PartyStatusIndicator(),
                        ),
                        SizedBox(height: PlatformConfig.height(context) * 0.01),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: verticalSpacerDefault),

              // Level indicator (now driven by visit XP)
              LevelIndicator(
                levelLabel: u.level.toInt() == 1337
                    ? 'Level 1337'
                    : 'Level ${p.level.toInt()}',
                current: u.level.toInt() == 1337 ? 69 : currentXp.toInt(),
                total: u.level.toInt() == 1337 ? 420 : xpThisLevel.toInt(),
                height: PlatformConfig.height(context) * 0.05,
                gradient: const LinearGradient(
                    colors: [owlPurple, purple, owlPurple, purple]),
                trackColor: grey,
                // onTap: _openLevelPopup, //TODO
              ),

              const SizedBox(height: verticalSpacerDefault),

              const Expanded(
                child: VisitsSection(
                  maxHeight: null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openStats() {}
  void _openSeeAllEmblems() {}
  void _openSeeAllVisits() {}
  void _openLevelPopup() {}
}
