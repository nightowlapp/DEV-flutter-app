// lib/models/users/location_audience.dart
enum LocationAudience {
  none,
  friends,
  closeFriends;

  static LocationAudience fromRaw(String? raw) {
    if (raw == null || raw.isEmpty) return LocationAudience.none;

    switch (raw) {
      case 'none':
        return LocationAudience.none;
      case 'friends':
        return LocationAudience.friends;
      case 'close_friends':
        return LocationAudience.closeFriends;
      default:
        return LocationAudience.none;
    }
  }

  /// String stored in Firestore (`locations/{uid}.audience`)
  String get raw {
    switch (this) {
      case LocationAudience.none:
        return 'none';
      case LocationAudience.friends:
        return 'friends';
      case LocationAudience.closeFriends:
        return 'close_friends';
    }
  }
}
