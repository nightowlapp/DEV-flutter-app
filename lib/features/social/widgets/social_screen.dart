// lib/features/social/widgets/social_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/data/providers/users/friends/friends_provider.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';

import '../utility/find_friends_section.dart';
import '../utility/friend_requests_section.dart';
import '../utility/my_friends_section.dart';

class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider).maybeWhen(
      data: (v) => v,
      orElse: () => const [],
    );

    return Scaffold(
      backgroundColor: black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (friends.isNotEmpty) ...[
                const MyFriendsSection(),
              ],

              const FriendRequestsSection(),
              // const SizedBox(height: 16),
              const FindFriendsSection(),
            ],
          ),
        ),
      ),
    );
  }
}
