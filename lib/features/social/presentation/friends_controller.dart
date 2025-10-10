import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

import '../../../models/users/user.dart';

class FriendsController extends StateNotifier<List<User>> {
  FriendsController()
      : super([
          //TODO
          User(
              id: '',
              email: '',
              userName: '',
              birthDate: DateTime.now(),
              gender: Gender.male),
        ]);
}
