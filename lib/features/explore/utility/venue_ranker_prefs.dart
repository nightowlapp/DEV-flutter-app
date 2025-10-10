// lib/shared/utility/venue_ranker_prefs.dart
import 'package:nightowlcode/models/users/user.dart' as model;
import 'package:nightowlcode/shared/constants/enums.dart';

class UserPrefs {
  final Set<VenueType> preferredTypes;
  final double maxDistanceKm;
  final int age;
  final PartyStatusTypes partyStatus;
  final Gender gender;

  const UserPrefs({
    required this.preferredTypes,
    required this.maxDistanceKm,
    required this.age,
    required this.partyStatus,
    required this.gender,
  });

  factory UserPrefs.fromUser(model.User u) => UserPrefs(
      preferredTypes: u.preferredVenueTypes,
      maxDistanceKm: u.maxDistanceKm,
      age: u.age,
      partyStatus: u.currentPartyStatus,
      gender: u.gender);
}
