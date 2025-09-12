import 'package:flutter/material.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/features/main/widgets/utility/owls_online_section_left_drawer.dart';
import 'package:nightowlcode/features/main/widgets/utility/refer_a_friend_section_left_drawer.dart';
import 'package:nightowlcode/features/main/widgets/utility/saftey_mode_toggle_section_left_drawer.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import '../../../shared/reusable/users/profile_picture_avatar.dart';


class MainScreenLeftDrawer extends StatelessWidget {
  const MainScreenLeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final width = PlatformConfig.width(context) * 0.5;

    return Drawer(
      surfaceTintColor: owlOrange.withOpacity(0.01),
      shadowColor: grey,
      backgroundColor: black,
      width: width,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(300),
          bottomRight: Radius.circular(300),
        ),
        side: BorderSide(color: grey, width: 0.7),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: sidePaddingDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------- TOP ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    // onTap: () => context.goScreen(MainScreenName.profile), // TODO Go to website.
                    child: CircleAvatar(
                      radius: PlatformConfig.width(context) * 0.09,
                      child: Image.asset('assets/nightowl/logo.png'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: verticalSpacerMedium),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: PlatformConfig.width(context) * 0.4, child:
                    Text('Owlnight.com', style: Styles.linkText(context))
                  ),],
              ),
              const Divider(color: owlOrange),
              const SizedBox(height: verticalSpacerSmall),

              const OwlsOnlineSectionLeftDrawer(online: 29324, total: 35735,),

              const SizedBox(height: verticalSpacerSmall),
              const Divider(color: owlOrange),
              const SizedBox(height: verticalSpacerSmall),

              // const OwlsOnlineSectionLeftDrawer(online: 29324, total: 35735,), //TODO Owls nearby?
              const ReferAFriendLeftDrawer(inviteCode: 'aszxe213',), //TODO functionallity

              const SizedBox(height: verticalSpacerSmall),
              const Divider(color: owlOrange),
              const SizedBox(height: verticalSpacerSmall),


              const SafetyModeToggle(
              //TODO brain storm hvad dette gør. Sender notifikation til venner? Forøger deres icon på map? Beder personen tjekke ind hvert 15/30 sekund - ellers slår den alarm? Ringe til Politiet?
              //TODO Mpåske skifter hele layoutet til Ring til politi - alt er lukket ned udover "livsvigtige funktioner"?
              //TODO Undersøg hvad nuværende tiltag har og folk bruger.
              //TODO Safety mode? Nødopkald? Share location to friends with message "going home"
              // isOn: false,
              //   selectedDurationMinutes: 180,
              //   trustedContactsCount: 3,
              //   // onChanged: (v) {
              //   // return null
              //   //   TODO: wire to provider/state + start/stop location sharing
              //   // },
              //   onDurationSelected: (m) {
              //     // TODO: update provider/state with duration m
              //   },
              //   onManageTrusted: () {
              //     // TODO: navigate to /settings/safety or similar
              //   },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


