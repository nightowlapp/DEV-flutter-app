import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/profile/widgets/timeline_section.dart';
import 'package:nightowlcode/features/profile/widgets/visits_section.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';

import '../../../core/platform_config.dart';
import '../../../shared/constants/values.dart';
import '../../../shared/reusable/ui/buttons.dart';
import '../../../shared/reusable/users/party_status_indicator.dart';
import '../../../shared/reusable/users/profile_picture_avatar.dart';
import 'achievements_section.dart';
import 'level_indicator.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});
  @override
  ConsumerState<MyProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<MyProfileScreen> {
  final List<String> _favoriteVenueImages =
    List.generate(12, (_) => 'assets/nightowl/test.png'); // demo data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 6), // TOdo sort padding on all screens at some point
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(children: [ // TODO make "top_section_profile"
                  // Avatar
                  ProfilePictureAvatar( //TODO
                    imageUrl: 'assets/nightowl/test.png',
                    size: PlatformConfig.width(context) * 0.25,
                  ),
                  const SizedBox(width: horizontalSpacerDefault,),
                  // Full name and username
                  Expanded(
                    child: FittedBox( // TODO make "as big as possilbe" but auto scale if too big.
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Poul Magne Skov', style: Styles.fullNameDisplay),   // larger base
                          const SizedBox(height: verticalSpacerVerySmall),
                          Text('Magnompower', style: Styles.usernameDisplay),       // smaller base
                        ],
                      ),
                    ),
                  ),
                  Spacer(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    // mainAxisSize: MainAxisSize.max,
                    children: [
                      OwlButton(label: 'My stats', onPressed: () {}
                      ),
                      const SizedBox(height: 15,), // Make smarter! Doenst fit TODO Not now.
                      const PartyStatusIndicator(),
                    ],)

                ]),

              SizedBox(height: verticalSpacerDefault,),

              Column(children: [
                  Column(children: [
                      // Text("Level 7"),
                      // SizedBox(height: verticalSpacerSmall),

                      LevelIndicator(
                        levelLabel: 'Level 7',
                        current: 76,
                        height: PlatformConfig.height(context) * 0.05,
                        gradient: LinearGradient(colors: [
                            owlOrange,
                            // Color(0xFFFFD54F),
                            owlOrange]), //TODO inplicit colors
                        trackColor: Color(0xFF1E1E1E), total: 100,
                      ),]),

                  const SizedBox(height: verticalSpacerDefault),

                  AchievementsSection(),

                  const SizedBox(height: verticalSpacerDefault),

                  TimelineSection(
                    height: PlatformConfig.height(context) * 0.2,

                    data: [
                      WeekHours(week: 0, hours: 1.0),
                      WeekHours(week: 1, hours: 12.5),
                      WeekHours(week: 2, hours: 23.0),
                      WeekHours(week: 3, hours: 34.0),
                      WeekHours(week: 4, hours: 45.5),
                      WeekHours(week: 5, hours: 6.0),
                      WeekHours(week: 6, hours: 17.0),
                      WeekHours(week: 7, hours: 28.5),
                      WeekHours(week: 8, hours: 39.0),
                      WeekHours(week: 9, hours: 50.0),
                      WeekHours(week: 10, hours: 11.5),
                      WeekHours(week: 11, hours: 22.0),
                      WeekHours(week: 12, hours: 33.0),
                      WeekHours(week: 13, hours: 44.5),
                      WeekHours(week: 14, hours: 5.0),
                      WeekHours(week: 15, hours: 16.0),
                      WeekHours(week: 16, hours: 27.5),
                      WeekHours(week: 17, hours: 38.0),
                      WeekHours(week: 18, hours: 49.0),
                      WeekHours(week: 19, hours: 10.5),
                      WeekHours(week: 20, hours: 21.0),
                      WeekHours(week: 21, hours: 32.5),
                      WeekHours(week: 22, hours: 43.0),
                      WeekHours(week: 23, hours: 4.0),
                      WeekHours(week: 24, hours: 15.5),
                      WeekHours(week: 25, hours: 26.0),
                      WeekHours(week: 26, hours: 37.0),
                      WeekHours(week: 27, hours: 48.0),
                      WeekHours(week: 28, hours: 9.5),
                      WeekHours(week: 29, hours: 20.0),
                      WeekHours(week: 30, hours: 31.0),
                      WeekHours(week: 31, hours: 42.5),
                      WeekHours(week: 32, hours: 3.0),
                      WeekHours(week: 33, hours: 14.0),
                      WeekHours(week: 34, hours: 25.5),
                    ],
                  ),

                  const SizedBox(height: verticalSpacerDefault),

                  VisitsSection()

                ]),
              // SizedBox(height: 60,),
              //
              // Row(children: [Text("Visited clubs - Amount of visits for each")],),
              //
              // Row(children: [Text("GAMIFICATION")],),
              // Row(children: [Text("MINE BESØGTE STEDER SLIDE NEDAD")],),
              // Row(children: [Text("Best/trusted friends? Max 5?")],),

            ],
          ),
        ),
      ),
    );
  }
}
