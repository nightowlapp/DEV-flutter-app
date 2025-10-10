import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/profile/presentation/change_profile_picture.dart';
import 'package:nightowlcode/features/profile/widgets/timeline_section.dart';
import 'package:nightowlcode/features/profile/widgets/visits_section.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/utility/level_logic.dart';

import '../../../core/platform_config.dart';
import '../../../data/providers/other_providers.dart';
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
          child: Center(child: CircularProgressIndicator(color: owlPurple)),
        ),
      );
    }

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

    return Scaffold(
      backgroundColor: black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                SizedBox(
                  height: PlatformConfig.height(context) * 0.12,
                  child: Row(
                    children: [
                      ProfilePictureAvatar(
                        size: PlatformConfig.width(context) * 0.25,
                        disablePrompt: false,
                      ),
                      const SizedBox(width: horizontalSpacerMedium),
                      // Full name and username
                      Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.displayFullName,
                                    style: Styles.fullNameDisplay),
                                const SizedBox(height: verticalSpacerVerySmall),
                                Text(u.userName, style: Styles.usernameDisplay),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Right side
                SizedBox(
                  height: PlatformConfig.height(context) * 0.12,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(height: PlatformConfig.height(context) * 0.01),
                      SizedBox(
                        height: PlatformConfig.height(context) * 0.03,
                        width: PlatformConfig.width(context) * 0.25,
                        child: 1 > 2
                            ? OwlButton(
                                label: 'My Stats',
                                onPressed: _openStats,
                                fullWidth: false,
                                textColor: owlPurple,
                                borderColor: transparent,
                                backgroundColor: black,
                                textStyle: Styles.basicText,
                              )
                            : const SizedBox.shrink(),
                      ),
                      SizedBox(height: PlatformConfig.height(context) * 0.02),
                      SizedBox(
                        height: PlatformConfig.height(context) * 0.03,
                        width: PlatformConfig.width(context) * 0.25,
                        child: const PartyStatusIndicator(),
                      ),
                      SizedBox(height: PlatformConfig.height(context) * 0.01),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: verticalSpacerDefault),

              // Level indicator
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
              ),

              const SizedBox(height: verticalSpacerDefault),

              const EmblemsSection(achieved: 37, total: 113),

              const SizedBox(height: verticalSpacerDefault),

              // ✅ Let visits fill the rest
              const Expanded(
                child: VisitsSection(
                  // maxHeight: null => use parent constraints (fill downwards)
                  maxHeight: null,
                ),
              ),

              // If you later want content below, keep it after the Expanded in another Column or a bottom bar.
            ],
          ),
        ),
      ),
    );
  }

  void _openStats() {}
  void _openSeeAllEmblems() {}
  void _openSeeAllVisits() {}
}
