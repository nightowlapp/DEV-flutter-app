// import 'package:flutter/material.dart';
//
// /// Simple, scalable, customizable, reusable horizontal avatar strip.
// /// - Generic over your item type [T] via resolver callbacks
// /// - Pads to [minSlots] with placeholders to keep width stable
// /// - Supports circle or rounded-rect avatars, custom borders, spacing, etc.
// /// - Single-class implementation for easy drop-in
// class VenueAvatar<T> extends StatelessWidget {
//   const VenueAvatar({
//     super.key,
//     required this.items,
//     required this.imageOf,
//     this.onTapItem,
//     this.borderColorOf,
//     this.semanticLabelOf,
//     this.emptyText = '',
//     this.emptyTextStyle,
//     this.minSlots = 0,
//     this.radius = 20,
//     this.spacing = 6,
//     this.borderWidth = 1,
//     this.placeholderWidthFactor = 1.1,
//     this.backgroundColor,
//     this.circular = true,
//     this.cornerRadius = 12,
//     this.controller,
//     this.physics,
//     this.padding = const EdgeInsets.symmetric(horizontal: 4),
//     this.placeholderBuilder,
//     this.errorChild = const Icon(Icons.broken_image, size: 16),
//   });
//
//   /// Items to render.
//   final List<T> items;
//
//   /// Resolve an image for each item. Return null to show [errorChild].
//   final ImageProvider<Object>? Function(T item) imageOf;
//
//   /// Optional per-item border color (e.g., status). Return null for no border.
//   final Color Function(T item)? borderColorOf;
//
//   /// Optional item tap handler.
//   final void Function(T item)? onTapItem;
//
//   /// Optional semantic label per item for accessibility.
//   final String Function(T item)? semanticLabelOf;
//
//   /// Text when list is empty (used if [placeholderBuilder] is null for empty).
//   final String emptyText;
//   final TextStyle? emptyTextStyle;
//
//   /// Pad to at least this many slots for stable width.
//   final int minSlots;
//
//   /// Avatar content radius (border is drawn outside this box).
//   final double radius;
//
//   /// Horizontal spacing between avatars/placeholders.
//   final double spacing;
//
//   /// Border stroke width around each avatar.
//   final double borderWidth;
//
//   /// Placeholder width multiplier relative to avatar diameter.
//   final double placeholderWidthFactor;
//
//   /// Background color under the image.
//   final Color? backgroundColor;
//
//   /// If true, circle; otherwise rounded rectangle with [cornerRadius].
//   final bool circular;
//
//   /// Corner radius used when [circular] is false.
//   final double cornerRadius;
//
//   /// Scroll behavior.
//   final ScrollController? controller;
//   final ScrollPhysics? physics;
//   final EdgeInsets padding;
//
//   /// Optional custom builder for placeholder slots (including empty-list state).
//   /// Signature: (context, slotIndex, diameter) -> Widget
//   final Widget Function(BuildContext, int, double)? placeholderBuilder;
//
//   /// Fallback widget shown when image fails or is null.
//   final Widget errorChild;
//
//   double get _diameter => radius * 2;
//
//   @override
//   Widget build(BuildContext context) {
//     if (items.isEmpty) {
//       // If a custom placeholderBuilder exists, honor it for empty UI.
//       final customEmpty = placeholderBuilder?.call(context, 0, _diameter);
//       if (customEmpty != null) {
//         return _wrapScroll(Row(children: [_hPad(customEmpty)]));
//       }
//       return Center(
//         child: Text(emptyText, style: emptyTextStyle ?? Theme.of(context).textTheme.bodyMedium),
//       );
//     }
//
//     final displayCount = (items.length < minSlots) ? minSlots : items.length;
//
//     return _wrapScroll(
//       Row(
//         children: List.generate(displayCount, (index) {
//           if (index >= items.length) {
//             return _hPad(_buildPlaceholder(context, index));
//           }
//           final item = items[index];
//           final borderColor = borderColorOf?.call(item);
//           final image = imageOf(item);
//           return _hPad(
//             Semantics(
//               label: semanticLabelOf?.call(item),
//               button: onTapItem != null,
//               child: GestureDetector(
//                 onTap: onTapItem == null ? null : () => onTapItem!(item),
//                 behavior: HitTestBehavior.opaque,
//                 child: _buildAvatar(
//                   borderColor: borderColor,
//                   image: image,
//                 ),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
//
//   // ---- Layout helpers -------------------------------------------------------
//
//   Widget _wrapScroll(Widget child) {
//     return SingleChildScrollView(
//       controller: controller,
//       scrollDirection: Axis.horizontal,
//       physics: physics ?? const BouncingScrollPhysics(),
//       padding: padding,
//       child: child,
//     );
//   }
//
//   Widget _hPad(Widget child) => Padding(
//     padding: EdgeInsets.symmetric(horizontal: spacing),
//     child: child,
//   );
//
//   // ---- Avatar / Placeholder builders ----------------------------------------
//
//   Widget _buildPlaceholder(BuildContext context, int slotIndex) {
//     final custom = placeholderBuilder?.call(context, slotIndex, _diameter);
//     if (custom != null) return custom;
//
//     // Default: keep width stable with an empty box matching desired width.
//     return SizedBox(width: _diameter * placeholderWidthFactor, height: _diameter);
//   }
//
//   Widget _buildAvatar({
//     required Color? borderColor,
//     required ImageProvider<Object>? image,
//   }) {
//     final decoration = circular
//         ? BoxDecoration(
//       shape: BoxShape.circle,
//       color: backgroundColor,
//       border: (borderColor == null)
//           ? null
//           : Border.all(color: borderColor, width: borderWidth),
//     )
//         : BoxDecoration(
//       color: backgroundColor,
//       borderRadius: BorderRadius.circular(cornerRadius),
//       border: (borderColor == null)
//           ? null
//           : Border.all(color: borderColor, width: borderWidth),
//     );
//
//     final content = image == null
//         ? Center(child: errorChild)
//         : Image(
//       image: image,
//       width: _diameter,
//       height: _diameter,
//       fit: BoxFit.cover,
//       errorBuilder: (_, __, ___) => Center(child: errorChild),
//     );
//
//     // We draw border via outer container and clip inner to shape.
//     final clipper = circular
//         ? ClipOval(child: content)
//         : ClipRRect(borderRadius: BorderRadius.circular(cornerRadius), child: content);
//
//     return Container(
//       width: _diameter,
//       height: _diameter,
//       decoration: decoration,
//       clipBehavior: Clip.antiAlias,
//       child: clipper,
//     );
//   }
// }
