import 'package:flutter/material.dart';
import 'package:nightowlcode/features/admin/widgets/party_status_section.dart';
import 'package:nightowlcode/features/admin/widgets/total_users_section.dart';
import 'package:nightowlcode/features/admin/widgets/user_growth_section.dart';
import 'package:nightowlcode/features/admin/widgets/venues_section.dart';
import 'package:nightowlcode/features/main/widgets/main_app_bar.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

import 'club_favorties_section.dart';
import 'club_likes_section.dart';

void main() => runApp(const AdminScreen());

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black,
      // appBar: MainAppBar(
      //   title: Text('Admin Panel'),
      //   backgroundColor: adminColor,
      // ),
      body: ListView(
        padding: const EdgeInsets.only(left: 6.0, right: 6.0),
        children: [
          const TotalUsersSection(), //TODO use riverpod for all. And corret ui from last app.
          Divider(color: adminColor, thickness: 0.5),
          // const TestUsersSection(),
          // Divider(color: adminColor, thickness: 0.5),
          const UserGrowthSection(),
          Divider(color: adminColor, thickness: 0.5),
          // const PartyStatusSection(),
          // Divider(color: adminColor, thickness: 0.5),
          ClubFavoritesSection(),
          Divider(color: adminColor, thickness: 0.5),
          // ClubLikesSection(),
          // Divider(color: adminColor, thickness: 0.5),
          VenuesSection(),
        ],
      ),
    );
  }
}
