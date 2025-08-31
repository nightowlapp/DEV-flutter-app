import 'package:flutter/material.dart';

import '../../constants/colors.dart';

/// A customizable circular profile picture with optional ring border and status dot.
///
/// Usage:
/// ProfilePictureAvatar(
///   imageUrl: user.photoUrl,               // <- from your user model
///   size: 44,
///   borderColor: Colors.orange,
///   borderWidth: 2,
///   profileIcon: Icons.person,             // shown if image is null/empty or fails
///   backgroundColor: Colors.black54,
///   showStatus: true,
///   statusColor: Colors.greenAccent,
///   statusPosition: Alignment.bottomRight,
///   // Optional: custom add-image behavior when the default sheet's action is tapped
///   onAddImage: () { /* open picker / navigate */ },
///   // If you provide onTap, it overrides the default "Add image" sheet behavior:
///   // onTap: () => print('Avatar tapped'),
///   tooltip: 'Go to profile',
///   heroTag: 'user-avatar-123',
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
    this.profileIcon = Icons.person, // fallback when no image
    this.profileIconColor,
    this.showStatus = false,
    this.statusColor = Colors.greenAccent,
    this.statusSize = 10,
    this.statusPosition = Alignment.bottomRight,
    this.onTap,
    this.onLongPress,
    this.onAddImage,
    this.tooltip,
    this.heroTag,
    this.semanticLabel,
    this.elevation = 0,
  })  : assert(size > 0),
        assert(statusSize >= 0);

  /// Load from a network URL (e.g. user.photoUrl).
  final String? imageUrl;

  /// Or pass any ImageProvider (AssetImage, MemoryImage, etc).
  final ImageProvider? imageProvider;

  /// Diameter in logical pixels.
  final double size;

  /// Optional circular border ring.
  final Color? borderColor;
  final double borderWidth;

  /// Circle background behind the image/placeholder.
  final Color? backgroundColor;

  /// Initials fallback (used only if no image and no profileIcon customization needed).
  final String? initials;
  final TextStyle? initialsStyle;

  /// Fallback icon when no image.
  final IconData profileIcon;
  final Color? profileIconColor;

  /// Online/status indicator.
  final bool showStatus;
  final Color statusColor;
  final double statusSize;
  final Alignment statusPosition;

  /// Interactions.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Called when user taps "Add image" from the default bottom sheet
  /// (only shown when there's no image and onTap is not provided).
  final VoidCallback? onAddImage;

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

    // Build the avatar core
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

    // Wrap for taps:
    avatar = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      elevation: elevation,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _handleTap(context),
        onLongPress: onLongPress,
        child: avatar,
      ),
    );

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
        button: true,
        child: avatar,
      );
    }

    // Always enforce exact size
    return SizedBox(width: size, height: size, child: avatar);
  }

  void _handleTap(BuildContext context) {
    // If the caller provided an explicit onTap, honor it.
    if (onTap != null) {
      onTap!.call();
      return;
    }

    // Otherwise: when pressed AND no image, show "Add image" popup.
    final hasImage = _resolveImageProvider() != null;
    if (!hasImage) {
      _showAddImageSheet(context);
    }
  }

  void _showAddImageSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_a_photo_outlined),
                title: const Text('Add image'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onAddImage?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(double radius, BuildContext context) {
    final resolved = _resolveImageProvider();

    // Background circle
    final bg = transparent;

    // We use ClipOval + Image to get a reliable errorBuilder fallback.
    Widget content;
    if (resolved != null) {
      content = ClipOval(
        child: Image(
          image: resolved,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _placeholder(radius, context),
        ),
      );
    } else {
      content = _placeholder(radius, context);
    }

    return DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: content,
    );
  }

  ImageProvider? _resolveImageProvider() {
    if (imageProvider != null) return imageProvider;

    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) return null;

    // If it looks like a network URL, use NetworkImage; otherwise treat as asset path.
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');
    return isNetwork ? NetworkImage(url) : AssetImage(url);
  }

  Widget _placeholder(double radius, BuildContext context) {
    // Prefer profile icon fallback as requested.
    if (profileIcon != Icons.no_accounts) {
      return Center(
        child: Icon(
          profileIcon,
          size: radius, // visually balanced
          color: profileIconColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
        ),
      );
    }

    // If someone disables profileIcon explicitly, show initials (if provided).
    final value = (initials ?? '').trim();
    final safe = value.isEmpty
        ? ''
        : value.split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();

    return Center(
      child: Text(
        safe,
        style: initialsStyle ??
            TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: radius * 0.8 / 2, // approximate fit
            ),
        textAlign: TextAlign.center,
      ),
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
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                // Small border ring so the dot isn't glued to the avatar edge.
                border: Border.all(
                  color: Colors.white,
                  width: (statusSize * 0.18).clamp(1.0, 3.0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
