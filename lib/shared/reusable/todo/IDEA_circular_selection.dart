// // lib/shared/widgets/going_out_indicator.dart
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:nightowlcode/shared/constants/colors.dart';
//
// import '../constants/enums.dart';
//
//
// class GoingOutIndicator extends StatefulWidget {
//   const GoingOutIndicator({super.key});
//
//   @override
//   State<GoingOutIndicator> createState() => _GoingOutIndicatorState();
// }
//
// class _GoingOutIndicatorState extends State<GoingOutIndicator> {
//   PartyStatusTypes _status = PartyStatusTypes.staying_home;
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(12),
//       onTap: () async {
//         HapticFeedback.selectionClick();
//         final picked = await _showWheelPicker(context, initial: _status);
//         if (picked == null) return;
//
//         // Simulate a tiny DB write
//         await Future.delayed(const Duration(milliseconds: 250));
//         if (!mounted) return;
//
//         setState(() => _status = picked);
//         HapticFeedback.lightImpact();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Status updated: ${_label(_status)}')),
//         );
//       },
//       child: const Padding(
//         padding: EdgeInsets.all(6),
//         child: Icon(Icons.my_location, size: 24),
//       ),
//     ).iconColor(_statusColor(_status));
//   }
// }
//
// /* ---------- Wheel Picker (dialog) ---------- */
//
// Future<PartyStatusTypes?> _showWheelPicker(
//     BuildContext context, {
//       required PartyStatusTypes initial,
//     }) {
//   return showDialog<PartyStatusTypes>(
//     context: context,
//     barrierDismissible: true,
//     builder: (_) => _WheelDialog(initial: initial),
//   );
// }
//
// class _WheelDialog extends StatefulWidget {
//   const _WheelDialog({required this.initial});
//   final PartyStatusTypes initial;
//
//   @override
//   State<_WheelDialog> createState() => _WheelDialogState();
// }
//
// class _WheelDialogState extends State<_WheelDialog> {
//   late double _rotation; // radians
//   late int _selected;
//   Offset? _center;
//   double? _startDragAngle;
//   double? _startRotation;
//
//   static final _items = PartyStatusTypes.values;
//   static final _seg = 2 * math.pi / _items.length;
//   static const _top = -math.pi / 2; // "up" direction
//
//   @override
//   void initState() {
//     super.initState();
//     _selected = _items.indexOf(widget.initial);
//     _rotation = _top - (_selected + 0.5) * _seg; // place initial under top
//   }
//
//   void _updateSelection() {
//     final raw = ((_top - _rotation) / _seg) - 0.5;
//     int idx = raw.round() % _items.length;
//     if (idx < 0) idx += _items.length;
//     if (idx != _selected) setState(() => _selected = idx);
//   }
//
//   double _angleFrom(Offset p) => math.atan2(p.dy - _center!.dy, p.dx - _center!.dx);
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.black,
//       insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
//       child: LayoutBuilder(
//         builder: (context, c) {
//           final size = math.min(c.maxWidth, c.maxHeight);
//           return Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const SizedBox(height: 8),
//                 Text(
//                   _label(_items[_selected]),
//                   style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 8),
//                 Stack(
//                   alignment: Alignment.topCenter,
//                   children: [
//                     const _TopIndicator(),
//                     GestureDetector(
//                       behavior: HitTestBehavior.opaque,
//                       onPanStart: (d) {
//                         final box = context.findRenderObject() as RenderBox;
//                         final local = box.globalToLocal(d.globalPosition);
//                         _center = Offset(c.maxWidth / 2 - 16, c.maxHeight / 2 - 16);
//                         _startDragAngle = _angleFrom(local);
//                         _startRotation = _rotation;
//                       },
//                       onPanUpdate: (d) {
//                         if (_center == null) return;
//                         final box = context.findRenderObject() as RenderBox;
//                         final local = box.globalToLocal(d.globalPosition);
//                         final current = _angleFrom(local);
//                         setState(() => _rotation = _startRotation! + (current - _startDragAngle!));
//                         _updateSelection();
//                       },
//                       child: SizedBox(
//                         width: size,
//                         height: size,
//                         child: RepaintBoundary(
//                           child: CustomPaint(
//                             painter: _WheelPainter(
//                               rotation: _rotation,
//                               items: _items,
//                               selectedIndex: _selected,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context, null),
//                       child: const Text('Cancel'),
//                     ),
//                     FilledButton(
//                       onPressed: () => Navigator.pop(context, _items[_selected]),
//                       style: FilledButton.styleFrom(backgroundColor: _statusColor(_items[_selected])),
//                       child: const Text('Done'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class _TopIndicator extends StatelessWidget {
//   const _TopIndicator();
//
//   @override
//   Widget build(BuildContext context) {
//     return CustomPaint(
//       painter: _IndicatorPainter(),
//       size: const Size(double.infinity, 12),
//     );
//   }
// }
//
// class _IndicatorPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final p = Paint()..color = Colors.white..style = PaintingStyle.fill;
//     final w = 14.0, h = 8.0;
//     final path = Path()
//       ..moveTo(size.width / 2, 0)
//       ..lineTo(size.width / 2 - w / 2, h)
//       ..lineTo(size.width / 2 + w / 2, h)
//       ..close();
//     canvas.drawShadow(path, Colors.black, 2, true);
//     canvas.drawPath(path, p);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
//
// class _WheelPainter extends CustomPainter {
//   _WheelPainter({
//     required this.rotation,
//     required this.items,
//     required this.selectedIndex,
//   });
//
//   final double rotation;
//   final List<PartyStatusTypes> items;
//   final int selectedIndex;
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final r = math.min(size.width, size.height) / 2 - 8;
//     final center = Offset(size.width / 2, size.height / 2);
//     final seg = 2 * math.pi / items.length;
//
//     final bg = Paint()..color = const Color(0xFF111111);
//     canvas.drawCircle(center, r + 8, bg);
//
//     for (var i = 0; i < items.length; i++) {
//       final start = rotation + i * seg;
//       final paint = Paint()
//         ..style = PaintingStyle.fill
//         ..color = _statusColor(items[i]).withOpacity(i == selectedIndex ? 0.95 : 0.65);
//       canvas.drawArc(Rect.fromCircle(center: center, radius: r), start, seg, true, paint);
//     }
//
//     // inner donut hole (just for look)
//     final inner = Paint()..color = Colors.black;
//     canvas.drawCircle(center, r * 0.45, inner);
//   }
//
//   @override
//   bool shouldRepaint(covariant _WheelPainter old) =>
//       old.rotation != rotation || old.selectedIndex != selectedIndex || old.items != items;
// }
//
// /* ---------- Utils ---------- */
//
// extension _IconColor on Widget {
//   Widget iconColor(Color c) => IconTheme.merge(data: IconThemeData(color: c), child: this);
// }
//
// String _label(PartyStatusTypes s) {
//   final raw = s.name.replaceAll('_', ' ');
//   return raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);
// }
//
// Color _statusColor(PartyStatusTypes s) {
//   switch (s) {
//     case PartyStatusTypes.going_out:
//       return owlOrange; // light blue
//   // owlOrange; // green
//     case PartyStatusTypes.staying_home:
//       return grey; // grey
//       // case PartyStatusTypes.waiting:
//       //   return const Color(0xFFFFC107); // amber
//       // case PartyStatusTypes.pregame:
//       //   return const Color(0xFFFF6F00); // deep orange
//       // case PartyStatusTypes.house_party:
//       return const Color(0xFFAB47BC); // purple
//   // case PartyStatusTypes.heading_home:
//   //   return const Color(0xFF29B6F6); // light blue
//   // case PartyStatusTypes.recovering:
//   //   return const Color(0xFF26A69A); // teal
//     case PartyStatusTypes.waiting:
//       return Colors.yellow; // grey
//
//   }
// }
