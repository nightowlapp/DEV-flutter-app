// lib/models/map_state.dart
import '../../../models/users/friend.dart';
import '../../../models/venues/venue.dart';

class MapState {
  Map<String, Venue> venues = {};
  Map<String, Friend> friends = {};

  void updateVenues(Map<String, Venue> newVenues) => venues = newVenues;
  void updateFriends(Map<String, Friend> newFriends) => friends = newFriends;

  List<Venue> get venueList => venues.values.toList();
  List<Friend> get friendList => friends.values.toList();
}