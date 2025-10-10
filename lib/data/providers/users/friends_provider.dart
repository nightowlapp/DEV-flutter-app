import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/social/presentation/friends_controller.dart';
import '../../../models/users/user.dart';

final friendsProvider =
    StateNotifierProvider<FriendsController, List<User>>((ref) {
  return FriendsController();
});
