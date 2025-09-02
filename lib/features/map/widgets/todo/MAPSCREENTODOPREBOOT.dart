// // lib/features/map/widgets/map_screen.dart
// import 'package:flutter/material.dart' hide Viewport;
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
//
// import 'package:nightowlcode/data/other_providers.dart';
// import 'package:nightowlcode/models/venues/venue.dart';
// import 'package:nightowlcode/shared/constants/enums.dart'; // <-- VenueType
// import 'package:nightowlcode/shared/constants/icons.dart';
// import 'package:nightowlcode/shared/constants/values.dart';
// import 'package:nightowlcode/shared/constants/colors.dart';
// import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
//
// import '../../../data/services/location/location_controller.dart';
// import '../../../data/venue_providers.dart';
// import '../presentation/map_style.dart';
// import '../presentation/initial_camera_provider.dart';  // ← initialCameraProvider + fallbackCamera
//
// class MapScreen extends ConsumerStatefulWidget {
//   const MapScreen({super.key});
//   @override
//   ConsumerState<MapScreen> createState() => _MapScreenState();
// }
//
// class _MapScreenState extends ConsumerState<MapScreen>
//     with AutomaticKeepAliveClientMixin {
//   MapboxMap? _map;
//   bool _mapCreated = false;
//
//   ProviderSubscription<VenuesFc>? _fcSub; // ← reactive GeoJSON updates
//   final MapStyle _style = MapStyle();
//
//   // ✅ Use enums here
//   final bool _showClosed = true;
//   final Set<VenueType> _allowedTypes = const {
//     VenueType.bar,
//     VenueType.club,
//     VenueType.pub,
//     VenueType.beer_bar,
//     VenueType.cocktail_bar,
//     VenueType.wine_bar,
//     VenueType.sports_bar,
//     VenueType.karaoke_bar,
//     VenueType.gay_bar,
//   };
//
//   @override
//   bool get wantKeepAlive => true; // keep the map instance alive across tab switches
//
//   @override
//   void dispose() {
//     _fcSub?.close();
//     super.dispose();
//   }
//
//   Future<void> _onMapCreated(MapboxMap map) async {
//     if (_mapCreated) return;
//     _map = map;
//     _mapCreated = true;
//
//     await _map!.location.updateSettings(
//       LocationComponentSettings(
//         enabled: true,
//         accuracyRingColor: owlOrange.value,
//         accuracyRingBorderColor: white.value,
//         showAccuracyRing: true,
//       ),
//     );
//     await _map!.scaleBar.updateSettings(
//       ScaleBarSettings(enabled: false, isMetricUnits: true),
//     );
//     await _map!.attribution.updateSettings(
//       AttributionSettings(clickable: false, iconColor: transparent.value),
//     );
//
//     // Ensure style and apply filters
//     await _style.ensure(_map!);
//
//     // 👇 Convert enums → names only at the boundary to keep MapStyle generic
//     await _style.applyFilters(
//       _map!,
//       showClosed: _showClosed,
//       allowedTypes: _allowedTypes.map((e) => e.name).toSet(),
//     );
//
//     // 1) Push whatever we already have (synchronously)
//     final fcNow = ref.read(venuesGeoJsonProvider);
//     await _style.setVenueData(
//       _map!,
//       clusterableFc: fcNow.clusterable,
//       vipFc: fcNow.vip,
//     );
//
//     // 2) Keep updating map sources reactively (very cheap—just strings)
//     _fcSub = ref.listenManual<VenuesFc>(
//       venuesGeoJsonProvider,
//           (prev, next) async {
//         if (!mounted || _map == null) return;
//         await _style.setVenueData(
//           _map!,
//           clusterableFc: next.clusterable,
//           vipFc: next.vip,
//         );
//       },
//       fireImmediately: false,
//     );
//
//     // 3) Fly to precise location when it resolves
//     ref.listen<AsyncValue<CameraOptions>>(
//       initialCameraProvider,
//           (prev, next) {
//         next.whenData((cam) {
//           _map?.flyTo(cam, MapAnimationOptions(duration: 650));
//         });
//       },
//     );
//   }
//
//   Future<void> _centerOnUser() async {
//     // Centers to whatever initialCameraProvider resolves to now (user if available)
//     final cam = await ref.read(initialCameraProvider.future);
//     _map?.flyTo(cam, MapAnimationOptions(duration: 800));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//
//     // Show the map immediately with a fallback camera; no spinner.
//     final camAsync = ref.watch(initialCameraProvider);
//     final cam = camAsync.maybeWhen(
//       data: (c) => c,
//       orElse: () => fallbackCamera,
//     );
//
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       body: MapWidget(
//         key: const ValueKey('mapWidget'),
//         styleUri: MapboxStyles.DARK,
//         cameraOptions: cam,
//         onMapCreated: _onMapCreated,
//       ),
//       floatingActionButton: FloatingActionButton(
//         mini: true, // 24
//         tooltip: 'Center on user',
//         onPressed: _centerOnUser,
//         child: Icon(locationIcon),
//       ),
//     );
//   }
//
//   void openVenueList() {
//   }
// //   List<Widget> _openVenueList(BuildContext context, LatLng userLocation) {
// //     List<Venue> venues;
// //     return venues.map((v) {
// //       return ListTile(
// //         leading: Container(
// //           // width: kNormalSizeRadius * 2,
// //           // height: kNormalSizeRadius * 2,
// //           decoration: BoxDecoration(
// //             shape: BoxShape.circle,
// //             border: Border.all(
// //               color: v.isOpenNow(DateTime.now())
// //                   ? green
// //                   : red,
// //               width: 3.0,
// //             ),
// //           ),
// //           child: ClipOval(
// //             child: CachedNetworkImage(
// //               imageUrl: v.logoUrl,
// //               placeholder: (context, url) => const LoadingIndicator(),
// //               errorWidget: (context, url, error) => CachedNetworkImage(
// //                 imageUrl: v.typeOfClubImg,
// //                 placeholder: (context, url) =>
// //                 const LoadingIndicator(),
// //                 errorWidget: (context, url, error) => const Icon(Icons.error),
// //               ),
// //               fit: BoxFit.cover,
// //             ),
// //           ),
// //         ),
// //         title: Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             Expanded(
// //               child: Text(
// //                 ClubNameFormatter.formatClubName(v.name),
// //                 style: kTextStyleP1,
// //                 overflow: TextOverflow.ellipsis,
// //               ),
// //             ),
// //             Text(
// //               ClubAgeRestrictionFormatter
// //                   .displayClubAgeRestrictionFormattedOnlyAge(v),
// //               style: kTextStyleP2.copyWith(color: primaryColor),
// //             ),
// //             const SizedBox(width: kSmallPadding),
// //             Text(
// //               ClubDistanceCalculator.displayDistanceToClub(
// //                 club: v,
// //                 userLat: userLocation.latitude,
// //                 userLon: userLocation.longitude,
// //               ),
// //               style: kTextStyleP2.copyWith(color: primaryColor),
// //             ),
// //           ],
// //         ),
// //         subtitle: Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             Expanded(
// //               child: Text(
// //                 ClubNameFormatter.displayClubLocation(v),
// //                 style: kTextStyleP3.copyWith(color: primaryColor),
// //                 overflow: TextOverflow.ellipsis,
// //               ),
// //             ),
// //             Text(
// //               clubOpeningHoursFormatted,
// //               style: clubOpeningHoursFormatted.toLowerCase() ==
// //                   S.of(context).closed_today
// //                   ? kTextStyleP3.copyWith(color: redAccent)
// //                   : kTextStyleP3,
// //             ),
// //           ],
// //         ),
// //         onTap: () {
// //           Navigator.pop(context);
// //           ClubBottomSheet.showClubSheet(context: context, club: v);
// //         },
// //       );
// //     }).toList();
// //   }
// // }
// }
