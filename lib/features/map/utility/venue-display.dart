
openVenueList() {
}
//   List<Widget> _openVenueList(BuildContext context, LatLng userLocation) {
//     List<Venue> venues;
//     return venues.map((v) {
//       return ListTile(
//         leading: Container(
//           // width: kNormalSizeRadius * 2,
//           // height: kNormalSizeRadius * 2,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             border: Border.all(
//               color: v.isOpenNow(DateTime.now())
//                   ? green
//                   : red,
//               width: 3.0,
//             ),
//           ),
//           child: ClipOval(
//             child: CachedNetworkImage(
//               imageUrl: v.logoUrl,
//               placeholder: (context, url) => const LoadingIndicator(),
//               errorWidget: (context, url, error) => CachedNetworkImage(
//                 imageUrl: v.typeOfClubImg,
//                 placeholder: (context, url) =>
//                 const LoadingIndicator(),
//                 errorWidget: (context, url, error) => const Icon(Icons.error),
//               ),
//               fit: BoxFit.cover,
//             ),
//           ),
//         ),
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Expanded(
//               child: Text(
//                 ClubNameFormatter.formatClubName(v.name),
//                 style: kTextStyleP1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             Text(
//               ClubAgeRestrictionFormatter
//                   .displayClubAgeRestrictionFormattedOnlyAge(v),
//               style: kTextStyleP2.copyWith(color: primaryColor),
//             ),
//             const SizedBox(width: kSmallPadding),
//             Text(
//               ClubDistanceCalculator.displayDistanceToClub(
//                 club: v,
//                 userLat: userLocation.latitude,
//                 userLon: userLocation.longitude,
//               ),
//               style: kTextStyleP2.copyWith(color: primaryColor),
//             ),
//           ],
//         ),
//         subtitle: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Expanded(
//               child: Text(
//                 ClubNameFormatter.displayClubLocation(v),
//                 style: kTextStyleP3.copyWith(color: primaryColor),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             Text(
//               clubOpeningHoursFormatted,
//               style: clubOpeningHoursFormatted.toLowerCase() ==
//                   S.of(context).closed_today
//                   ? kTextStyleP3.copyWith(color: redAccent)
//                   : kTextStyleP3,
//             ),
//           ],
//         ),
//         onTap: () {
//           Navigator.pop(context);
//           ClubBottomSheet.showClubSheet(context: context, club: v);
//         },
//       );
//     }).toList();
//   }
// }