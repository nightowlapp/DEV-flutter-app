// import 'package:flutter/material.dart';
// import 'package:nightowlcode/features/main/widgets/main_app_bar.dart';
// import 'package:nightowlcode/shared/reusable/ui/buttons.dart';
//
// import '../../../core/platform_config.dart';
// import '../../../shared/constants/colors.dart';
// import '../../../shared/reusable/sign_up_or_login/sign_up.dart';
// import '../../../shared/reusable/ui/progress_bar.dart';
//
// class OptionalDetailsScreen extends StatefulWidget {
//   const OptionalDetailsScreen({super.key});
//
//   @override
//   State<OptionalDetailsScreen> createState() =>
//       _OptionalDetailsScreenState();
// }
//
// class _OptionalDetailsScreenState
//     extends State<OptionalDetailsScreen> { //TODO NOT needed right now.
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final horizontal = PlatformConfig.width(context) * 0.1;
//
//     return Scaffold(
//       appBar: const MainAppBar(showBack: true, titleText: 'Optional Details',
//         actions: [
//           CircleAvatar(backgroundImage: AssetImage('assets/nightowl/logo.png')),
//         ],),
//
//       body: SafeArea(
//         child:Padding(
//               padding: EdgeInsets.symmetric(horizontal: horizontal),
//           child: SignUp(
//             showProgressBar: true,
//             currentStep: 2,
//             totalSteps: 2,
//             formFields: [
//
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: OwlButton(
//                             label: 'Skip',
//                             textColor: white,
//                             onPressed: () {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(content: Text('Skip tapped')),
//                               );
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: OwlButton(
//                             textColor: grey,
//                             label: 'Save & Continue', onPressed: () {
//                           },
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                 ],
//               ),
//             ),
//             // Padding(padding: EdgeInsets.only(bottom: 20),child:
//             // ProgressBar(currentStep: 1, totalSteps: 2),
//             // ),
//         ),
//     );
//   }
// }
//
// /* ---------------------------- UI Building Blocks --------------------------- */
//
// class _ClubItem extends StatelessWidget {
//   const _ClubItem({
//     required this.club,
//     required this.isSelected,
//     required this.onTap,
//   });
//
//   final ClubData club;
//   final bool isSelected;
//   final VoidCallback onTap;
//
//   @override
//   Widget build(BuildContext context) {
//     const baseImage = 50.0;
//     const selectedImage = 55.0;
//
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           SizedBox(
//             width: 60,
//             child: Text(
//               club.name,
//               maxLines: 1,
//               textAlign: TextAlign.center,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 fontSize: 10,
//                 color: isSelected ? owlOrange : Colors.white,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           const SizedBox(height: 6),
//           Container(
//             width: isSelected ? selectedImage : baseImage,
//             height: isSelected ? selectedImage : baseImage,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: isSelected
//                   ? Border.all(color: owlOrange, width: 3)
//                   : null,
//             ),
//             child: ClipOval(
//               child: Image.network(
//                 club.logo,
//                 fit: BoxFit.cover,
//                 errorBuilder: (_, __, ___) => Container(
//                   color: const Color(0xFF222222),
//                   child: const Icon(Icons.local_bar, color: Colors.white70),
//                 ),
//                 loadingBuilder: (context, child, progress) {
//                   if (progress == null) return child;
//                   return Container(
//                     color: const Color(0xFF1A1A1A),
//                     alignment: Alignment.center,
//                     child: SizedBox(
//                       width: 18,
//                       height: 18,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor:
//                         AlwaysStoppedAnimation(_AppColors.secondaryColor),
//                         value: progress.expectedTotalBytes != null
//                             ? progress.cumulativeBytesLoaded /
//                             (progress.expectedTotalBytes ?? 1)
//                             : null,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _ActionButton extends StatelessWidget {
//   const _ActionButton._({
//     required this.label,
//     required this.onPressed,
//     required this.background,
//     required this.foreground,
//     required this.outlined,
//   });
//
//   factory _ActionButton.filled({
//     required String label,
//     required VoidCallback? onPressed,
//   }) =>
//       _ActionButton._(
//         label: label,
//         onPressed: onPressed,
//         background: owlOrange,
//         foreground: Colors.black,
//         outlined: false,
//       );
//
//   factory _ActionButton.ghost({
//     required String label,
//     required VoidCallback onPressed,
//   }) =>
//       _ActionButton._(
//         label: label,
//         onPressed: onPressed,
//         background: Colors.transparent,
//         foreground: Colors.white,
//         outlined: true,
//       );
//
//   final String label;
//   final VoidCallback? onPressed;
//   final Color background;
//   final Color foreground;
//   final bool outlined;
//
//   @override
//   Widget build(BuildContext context) {
//     final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
//     final style = outlined
//         ? OutlinedButton.styleFrom(
//       foregroundColor: foreground,
//       side: BorderSide(color: Colors.white.withOpacity(0.25)),
//       shape: shape,
//       padding: const EdgeInsets.symmetric(vertical: 14),
//     )
//         : FilledButton.styleFrom(
//       backgroundColor: background,
//       foregroundColor: foreground,
//       shape: shape,
//       padding: const EdgeInsets.symmetric(vertical: 14),
//       disabledBackgroundColor: Colors.white12,
//       disabledForegroundColor: Colors.white38,
//     );
//
//     return outlined
//         ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
//         : FilledButton(onPressed: onPressed, style: style, child: Text(label));
//   }
// }
//
// class _ProgressBar extends StatelessWidget {
//   const _ProgressBar({required this.currentStep, required this.totalSteps});
//
//   final int currentStep;
//   final int totalSteps;
//
//   @override
//   Widget build(BuildContext context) {
//     final segments = List.generate(totalSteps, (i) => i + 1);
//     return Row(
//       children: segments
//           .map(
//             (i) => Expanded(
//           child: Container(
//             height: 6,
//             margin: EdgeInsets.only(
//               right: i == segments.length ? 0 : 6,
//             ),
//             decoration: BoxDecoration(
//               color: i <= currentStep
//                   ? owlOrange
//                   : Colors.white12,
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//       )
//           .toList(),
//     );
//   }
// }
//
// /* ---------------------------------- Data ---------------------------------- */
//
// class ClubData {
//   final String id;
//   final String name;
//   final String logo;
//   final String typeOfClub;
//
//   ClubData({
//     required this.id,
//     required this.name,
//     required this.logo,
//     required this.typeOfClub,
//   });
// }
//
// final List<ClubData> _mockClubs = List.generate(18, (i) {
//   final n = i + 1;
//   return ClubData(
//     id: 'club_$n',
//     name: [
//       'Aurora',
//       'Nebula',
//       'Pulse',
//       'Velvet',
//       'Eclipse',
//       'Mirage',
//       'Noir',
//       'Voltage',
//       'Lunar',
//       'Prism',
//       'Afterglow',
//       'Monarch',
//       'Opal',
//       'Cascade',
//       'Zenith',
//       'Harbor',
//       'Vortex',
//       'Echo'
//     ][i],
//     // picsum seed keeps images stable between runs
//     logo: 'https://picsum.photos/seed/club$n/200',
//     typeOfClub: ['bar', 'club', 'lounge', 'disco'][i % 4],
//   );
// });
//
// /* --------------------------------- Styling -------------------------------- */
//
// class _AppColors {
//   static Color get secondaryColor => const Color(0xFF10D7A8);
// }
