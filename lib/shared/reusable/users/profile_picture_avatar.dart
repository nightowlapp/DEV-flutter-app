// lib/shared/reusable/ui/profile_picture_avatar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/reusable/ui/buttons.dart';

import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

import 'package:nightowlcode/shared/utility/custom_network_image.dart'; // ← your cached + Storage-aware image

// Providers (SSOT): current user + status color
import 'package:nightowlcode/data/other_providers.dart' show authUserProvider; // model.User?
import '../../../data/providers/party_status/party_status_provider.dart';
import '../../../features/profile/presentation/change_profile_picture.dart';
import '../ui/popup_dialog_default.dart';


/// A customizable circular profile picture with optional ring border and status dot.
///
/// - Self-sufficient by default: reads current user (photo URL) and party status color via Riverpod.
/// - Uses your CustomNetworkImage (supports http(s)/gs:///storage paths + cache).
/// - You can still pass overrides (imageUrl, onTap, etc.) when needed.
class ProfilePictureAvatar extends StatelessWidget {
  const ProfilePictureAvatar({
    super.key,
    this.imageUrl,
    this.imageProvider,

    this.size = 44,
    this.borderColor,
    this.borderWidth = 2,
    this.backgroundColor,

    this.onTap,
    this.onLongPress,
    this.onAddImage,
    this.tooltip,
    this.heroTag,
    this.semanticLabel,

    // Snack/prompt
    this.promptCooldown = const Duration(hours: 1),
    this.forcePrompt = false,
    this.cooldownKey,
    this.popupTitle = 'Add your profile picture',
    this.popupMessage = 'Upload a profile picture to your profile.',

    // Fallback rendering
    this.showOnlyInitials = false,
    this.initials,    // optional explicit initials; if null we derive from user
    this.disablePrompt = false,
  });

  // ---- Inputs / overrides ---------------------------------------------------
  final String? imageUrl;
  final ImageProvider? imageProvider;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onAddImage;
  final String? tooltip;
  final Object? heroTag;
  final String? semanticLabel;

  // Prompt/snack
  final Duration promptCooldown;
  final bool forcePrompt;
  final String? cooldownKey;
  final String popupTitle;
  final String popupMessage;

  // Fallback options
  final bool showOnlyInitials;
  final String? initials;
  final bool disablePrompt;

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;

    // Border ring is decided here; when auto is on AND no explicit color passed,
    // we read it from partyStatusColorProvider. Otherwise we use borderColor.
    return Consumer(
      builder: (context, ref, _) {
        // 1) Pull user (photo + id) – used for image and cooldownKey
        final userAsync = ref.watch(authUserProvider);
        final userPhotoUrl = userAsync.maybeWhen(
          data: (u) => u?.profilePictureUrl,
          orElse: () => null,
        );
        final userId = userAsync.maybeWhen(
          data: (u) => u?.id,
          orElse: () => null,
        );

        // Prefer explicit imageUrl override; otherwise use provider value
        final effectiveImageUrl = (imageUrl?.trim().isNotEmpty == true)
          ? imageUrl
          : userPhotoUrl;

        // Default cooldown key is user-scoped
        final effectiveCooldownKey = cooldownKey ?? 'avatar_${userId ?? 'anon'}';

        // 2) Border color (auto from status unless override provided)
        final autoColor = ref.watch(partyStatusColorProvider);
        final effectiveBorderColor =
          (borderColor == null)
            ? autoColor
            : (borderColor ?? transparent);
        final hasBorder =
          borderWidth > 0 && effectiveBorderColor != transparent;

        // 3) Build the avatar core
        Widget avatar = _buildAvatar(
          radius: radius,
          context: context,
          effectiveImageUrl: effectiveImageUrl,
          // If you pass imageProvider explicitly, we’ll use it instead.
          // Otherwise we render via CustomNetworkImage for caching + Storage paths.
        );

        if (tooltip != null) {
          avatar = Tooltip(message: tooltip!, child: avatar);
        }
        if (heroTag != null) {
          avatar = Hero(tag: heroTag!, child: avatar);
        }

        // 4) Taps: do the intended action AND maybe show snack
        avatar = Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _handleTap(
              context,
              effectiveImageUrl: effectiveImageUrl,
              effectiveCooldownKey: effectiveCooldownKey,
            ),
            onLongPress: onLongPress,
            child: avatar,
          ),
        );

        // 5) Border ring (now using effectiveBorderColor)
        if (hasBorder) {
          avatar = Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(borderWidth),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: effectiveBorderColor, width: borderWidth),
            ),
            child: avatar,
          );
        }

        // Semantics + final size
        Widget out = avatar;
        if (semanticLabel != null) {
          out = Semantics(label: semanticLabel, button: true, child: avatar);
        }
        return SizedBox(width: size, height: size, child: out);
      },
    );
  }

  // Replace your _handleTap with this:
  Future<void> _handleTap(
    BuildContext context, {
      required String? effectiveImageUrl,
      required String effectiveCooldownKey,
    }) async {
    // 1) Do the intended action first (open drawer, navigate, etc.)
    onTap?.call();

    // 2) Respect the "no prompt" switch
    if (disablePrompt) return;

    // 3) Only prompt when there's no image at all (http/gs/storage path or empty)
    if (_hasCandidateImage(effectiveImageUrl)) return;

    // 5) Show your popup
    await _showAddImagePopup(
      context,
      title: popupTitle,
      message: popupMessage,
      onAction: onAddImage,
    );
  }

  // Add this helper in the same class (below _handleTap is fine)
  static Future<void> _showAddImagePopup(
    BuildContext context, {
      required String title,
      String? message,
      VoidCallback? onAction, // keep if you want, but we’ll call changeProfilePicture
    }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => PopupDialogDefault(
        title: title,
        children: [
          if ((message ?? '').isNotEmpty)
          Text(message!, style: Styles.popupText),
          const SizedBox(height: 12),
          // inside ProfilePictureAvatar._showAddImagePopup(...)
          Row(
            children: [
              Expanded(
                child: Builder( // ensure a context under the dialog
                  builder: (dialogBtnCtx) {
                    return Consumer(
                      builder: (context, ref, _) {
                        return OwlButton( // TODO Unesseary many places. Just go straight to upload.
                          label: 'Upload',
                          onPressed: () async {
                            // stable container from the dialog context
                            final container = ProviderScope.containerOf(dialogBtnCtx, listen: false);
                            // close dialog first
                            Navigator.of(dialogCtx, rootNavigator: true).pop();
                            // run async work using the container (no disposed-ref issues)
                            await changeProfilePictureWithContainer(context, container);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Keep this helper; it just checks "is a non-empty path/URL provided?"
  static bool _hasCandidateImage(String? url) => (url ?? '').trim().isNotEmpty;

  /// Builds avatar with either:
  /// - explicit [imageProvider],
  /// - or Storage/http URL via [CustomNetworkImage],
  /// - or placeholder (NightOwl logo by default, or initials if [showOnlyInitials]).
  Widget _buildAvatar({
    required double radius,
    required BuildContext context,
    required String? effectiveImageUrl,
  }) {
    final bg = transparent;

    Widget content;
    if (imageProvider != null) {
      // Explicit ImageProvider → use it
      content = ClipOval(
        child: Image(
          image: imageProvider!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _placeholder(radius, context),
        ),
      );
    }
    else if (_hasCandidateImage(effectiveImageUrl)) {
      // Use your CustomNetworkImage: accepts http(s)/gs:///paths and caches
      content = ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: CustomNetworkImage(
            effectiveImageUrl!,              // can be storage path; normalize inside
            fit: BoxFit.cover,
            fallbackAsset: 'assets/nightowl/logo.png', // default logo fallback
            fallbackSize: Size(size, size),
          ),
        ),
      );
    }
    else {
      // No image candidate → placeholder
      content = _placeholder(radius, context);
    }

    return DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: content,
    );
  }

  Widget _placeholder(double radius, BuildContext context) {
    if (!showOnlyInitials) {
      // Default logo/icon
      return Center(
        child: Icon(profileIcon, size: radius, color: white),
      );
    }

    // Initials (either explicit or derived from nothing = empty)
    final value = (initials ?? '').trim();
    final safe = value.isEmpty
      ? ''
      : value.split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();

    return Center(
      child: Text(
        safe,
        style: Styles.boldText,
        textAlign: TextAlign.center,
      ),
    );
  }
}
