// import 'dart:async';
// import 'package:geolocator/geolocator.dart';
// import 'package:nightowlcode/data/repositories/venues/venue_repository.dart';
//
// import '../repositories/geofencing_repository.dart';
// import 'geofencing/geofencing_orchestrator.dart';
//
// class LocationService {
//   factory LocationService() => _instance;
//   LocationService._internal();
//   static final LocationService _instance = LocationService._internal();
//
//   StreamSubscription<Position>? _positionStream;
//   Position? _currentPosition;
//
//   // Initialize service and check/request permissions
//   Future<void> initialize() async {
//     final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       throw Exception('Location services are disabled.');
//     }
// //TODO There should always be a way to allow and then start the app. App should not work without locatiion
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.deniedForever) {
//         throw Exception('Location permissions are permanently denied.');
//       }
//       if (permission == LocationPermission.denied) {
//         throw Exception('Location permissions are denied.');
//       }
//     }
//   }
//
//   //TODO improve initialize
//
// //   Future<bool> initialize(BuildContext context) async {
// //     bool permissionGranted = false;
// //     while (!permissionGranted)７
// //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
// //     bool isPermanentlyDenied = (await Geolocator.checkPermission()) == LocationPermission.deniedForever;
// //
// //     if (!serviceEnabled || isPermanentlyDenied || (await Geolocator.checkPermission()) == LocationPermission.denied) {
// //     await showDialog(
// //     context: context,
// //     barrierDismissible: false,
// //     builder: (context) => AlertDialog(
// //     title: const Text('Location Permission Required'),
// //     content: Text(
// //     isPermanentlyDenied
// //     ? 'Location permissions are permanently denied. Please enable them in app settings.'
// //         : !serviceEnabled
// //     ? 'Location services are disabled. Please enable them.'
// //         : 'This app requires location permissions to function. Please grant access.',
// //     ),
// //     actions: [
// //     if (isPermanentlyDenied)
// //     TextButton(
// //     onPressed: () async {
// //     await Geolocator.openAppSettings();
// //     Navigator.pop(context);
// //     },
// //     child: const Text('Open Settings'),
// //     )
// //     else
// //     TextButton(
// //     onPressed: () async {
// //     if (!serviceEnabled) {
// //     await Geolocator.openLocationSettings();
// //     } else {
// //     await Geolocator.requestPermission();
// //     }
// //     Navigator.pop(context);
// //     },
// //     child: Text(!serviceEnabled ? 'Enable Services' : 'Retry'),
// //     ),
// //     ],
// //     ),
// //     );
// //     }
// //
// //     // Check permission after dialog
// //     LocationPermission permission = await Geolocator.checkPermission();
// //     permissionGranted = permission == LocationPermission.whileInUse || permission == LocationPermission.always;
// //   }
// //   return true; // Only returns when permissions are granted
// // }
//
//
//
//   // Get user's current location
//   Future<Position> getUserPosition() async {
//     _currentPosition = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//     return _currentPosition!;
//   }
//
//   // Stream user's background location
//   Stream<Position> getPositionStream() {
//     _positionStream?.cancel(); // Cancel any existing stream
//     return Geolocator.getPositionStream(
//       locationSettings: const LocationSettings(
//         accuracy: LocationAccuracy.high,
//         distanceFilter: 5, // Update every 5 meters Power consumption? TODO
//       ),
//     );
//   }
//
//   //TODO find where to put this: Want to keep all location logic in here.
//   // Using geolocator (example)
//   static final location$ = Geolocator.getPositionStream(
//     locationSettings: const LocationSettings(
//       accuracy: LocationAccuracy.best,
//       distanceFilter: 5, // meters
//     ),
//   ).map((p) => (lat: p.latitude, lng: p.longitude));
//
//
//   // Fetch friend locations from Firestore
//   // Stream<List<Map<String, dynamic>>> getFriendLocations(String userId) {
//   //   return
//   // } // TODO move to firestore
//
//   // Clean up
//
//   // Update user's location to Firestore TODO move to firestore
//   // Future<void> updateUserLocation(String userId, Position position) async {
//   //   await FirebaseFirestore.instance.collection('user_locations').doc(userId).set({
//   //     'latitude': position.latitude,
//   //     'longitude': position.longitude,
//   //     'lastUpdated': FieldValue.serverTimestamp(),
//   //   }, SetOptions(merge: true));
//   //   // TODO This overrides user location. Would be nice to collect
//   // }
//   void dispose() {
//     _positionStream?.cancel();
//   }
// }
