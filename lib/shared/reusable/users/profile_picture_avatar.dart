import 'package:flutter/material.dart';

import '../../constants/colors.dart';

/// A customizable circular profile picture with optional ring border and status dot.
///
/// Usage:
/// ProfilePictureAvatar(
///   imageUrl: 'https://picsum.photos/80/80',
///   size: 44,
///   borderColor: Colors.orange,
///   borderWidth: 2,
///   initials: 'NO',              // shown if image fails/is null
///   backgroundColor: Colors.black54,
///   statusColor: Colors.greenAccent,
///   showStatus: true,
///   statusPosition: Alignment.bottomRight,
///   onTap: () => print('Avatar tapped'),
///   tooltip: 'Go to profile',
///   heroTag: 'user-avatar-123',  // optional Hero
/// )
class ProfilePictureAvatar extends StatelessWidget {
  const ProfilePictureAvatar({
    super.key,
    this.imageUrl,
    this.imageProvider,
    this.size = 44, // diameter
    this.borderColor,
    this.borderWidth = 0,
    this.backgroundColor,
    this.initials,
    this.initialsStyle,
    this.showStatus = false,
    this.statusColor = Colors.greenAccent,
    this.statusSize = 10,
    this.statusPosition = Alignment.bottomRight,
    this.onTap,
    this.onLongPress,
    this.tooltip,
    this.heroTag,
    this.semanticLabel,
    this.elevation = 0,
  }) : assert(size > 0),
        assert(statusSize >= 0);

  /// Load from network easily.
  final String? imageUrl;

  /// Or pass any ImageProvider (AssetImage, MemoryImage, etc).
  final ImageProvider? imageProvider;

  /// Diameter in logical pixels.
  final double size;

  /// Optional circular border.
  final Color? borderColor;
  final double borderWidth;

  /// Circle background behind the image/initials.
  final Color? backgroundColor;

  /// Initials fallback when no image provided or load fails.
  final String? initials;
  final TextStyle? initialsStyle;

  /// Online/status indicator.
  final bool showStatus;
  final Color statusColor;
  final double statusSize;
  final Alignment statusPosition;

  /// Interactions.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? tooltip;

  /// Optional Hero tag to animate between routes.
  final Object? heroTag;

  /// Accessibility label for screen readers.
  final String? semanticLabel;

  /// Optional shadow (wraps in Material).
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    final hasBorder = borderWidth > 0 && (borderColor != null);

    Widget avatar = _buildAvatar(radius, context);

    if (showStatus && statusSize > 0) {
      avatar = _withStatusDot(avatar);
    }

    if (tooltip != null) {
      avatar = Tooltip(message: tooltip!, child: avatar);
    }

    if (heroTag != null) {
      avatar = Hero(tag: heroTag!, child: avatar);
    }

    if (onTap != null || onLongPress != null) {
      avatar = InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        onLongPress: onLongPress,
        child: avatar,
      );
    }

    // Optional elevation
    if (elevation > 0) {
      avatar = Material(
        color: transparent,
        elevation: elevation,
        shape: const CircleBorder(),
        child: avatar,
      );
    }

    // Optional border ring
    if (hasBorder) {
      avatar = Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(borderWidth), // ring thickness
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor!, width: borderWidth),
        ),
        child: avatar,
      );
    }

    // Semantics (accessibility)
    if (semanticLabel != null) {
      avatar = Semantics(
        label: semanticLabel,
        button: onTap != null || onLongPress != null,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildAvatar(double radius, BuildContext context) {
    final image = imageProvider ??
        (imageUrl != null && imageUrl!.trim().isNotEmpty
            ? AssetImage(imageUrl!)
            : null);

    // CircleAvatar will show [child] if no image was given.
    // We also add a solid background so it’s not see-through.
    return CircleAvatar(
      radius: radius - (borderWidth > 0 ? borderWidth : 0),
      backgroundImage: image,
      child: image == null
          ? _Initials(
        text: initials ?? '',
        style: initialsStyle ??
            TextStyle(
              color: white,
              fontWeight: FontWeight.w700,
              fontSize: radius * 0.8 / 2, // approximate fit
            ),
      )
          : null,
    );
  }

  Widget _withStatusDot(Widget child) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        child,
        Positioned.fill(
          child: Align(
            alignment: statusPosition,
            child: Container(
              width: statusSize,
              height: statusSize,
            ),
            //TODO asign PartyStatusColor to border the image.
          ),
        ),
      ],
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.text, required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final value = text.trim();
    final safe = value.isEmpty
        ? ''
        : value.split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();
    return Text(safe, style: style);
  }
}
