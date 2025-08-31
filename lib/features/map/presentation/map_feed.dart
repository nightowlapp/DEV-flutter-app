abstract class MapFeed {
  const MapFeed(this.onVenues, this.onFriends);

  // Callbacks to UI/style
  final void Function(String) onVenues;
  final void Function(String) onFriends;

  Future<void> refreshForCamera({
    required double lat,
    required double lng,
    required double zoom,
    bool force = false,
  });

  void startFriends({required double lat, required double lng});
  void dispose();
}

//TODO WHAT? Chat?

// @override
// Future<void> refreshForCamera({
//   required double lat,
//   required double lng,
//   required double zoom,
//   bool force = false,
// }) {
//   return queryVenuesForCamera(lat, lng, zoom, force: force);
// }
//
// @override
// void startFriends({required double lat, required double lng}) {
//   startFriendsStream(seedLat: lat, seedLng: lng);
// }
//
// @override
// void dispose() {
//   for (final s in _venueSubs) { s.cancel(); }
//   _friendsSub?.cancel();
//   _friendMockTimer?.cancel();
// }

