// lib/shared/reusable/ui/profile_picture_avatar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/utility/custom_network_image.dart';

import 'package:nightowlcode/data/providers/other_providers.dart' show authUserProvider;
import '../../../data/providers/party_status/party_status_provider.dart';
import '../../../features/profile/presentation/change_profile_picture.dart';

/// Circular profile picture with optional status-colored border.
/// - Reads current user (photo URL) and party status color via Riverpod.
/// - If [disablePrompt] is false, tapping opens the change-profile-picture flow.
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
    this.semanticLabel,
    this.showOnlyInitials = false,
    this.initials,
    this.disablePrompt = true,
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
  final String? semanticLabel;

  // Fallback options
  final bool showOnlyInitials;
  final String? initials;
  final bool disablePrompt;

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;

    return Consumer(
      builder: (context, ref, _) {
        // 1) Read current user photo
        final userAsync = ref.watch(authUserProvider);
        final userPhotoUrl = userAsync.maybeWhen(
          data: (u) => u?.profilePictureUrl,
          orElse: () => null,
        );

        // 2) Border color from party status (unless overridden)
        final autoColor = ref.watch(partyStatusColorProvider);
        final effectiveBorderColor = borderColor ?? autoColor;
        final hasBorder = borderWidth > 0 && effectiveBorderColor != transparent;

        // 3) Choose the image url: explicit override > user photo
        final effectiveImageUrl =
        (imageUrl?.trim().isNotEmpty == true) ? imageUrl : userPhotoUrl;

        // 4) Build avatar core
        Widget avatar = _buildAvatar(
          radius: radius,
          context: context,
          effectiveImageUrl: effectiveImageUrl,
        );

        // 5) Taps: always start change flow when not disabled
        avatar = Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              onTap?.call();
              if (disablePrompt) return;
              if (onAddImage != null) {
                onAddImage!();
              } else {
                // Start the change-profile-picture flow immediately
                await changeProfilePicture(context, ref);
              }
            },
            onLongPress: onLongPress,
            child: avatar,
          ),
        );

        // 6) Optional border ring
        if (hasBorder) {
          avatar = Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(borderWidth),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor ?? Colors.transparent,
              border: Border.all(color: effectiveBorderColor, width: borderWidth),
            ),
            child: avatar,
          );
        }

        final out = (semanticLabel != null)
            ? Semantics(label: semanticLabel, button: true, child: avatar)
            : avatar;

        return SizedBox(width: size, height: size, child: out);
      },
    );
  }

  // ---- Internals ------------------------------------------------------------

  static bool _hasCandidateImage(String? url) => (url ?? '').trim().isNotEmpty;

  Widget _buildAvatar({
    required double radius,
    required BuildContext context,
    required String? effectiveImageUrl,
  }) {
    final bg = backgroundColor ?? transparent;

    if (imageProvider != null) {
      return DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        child: ClipOval(
          child: Image(
            image: imageProvider!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => _placeholder(radius),
          ),
        ),
      );
    }

    if (_hasCandidateImage(effectiveImageUrl)) {
      return DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        child: ClipOval(
          child: SizedBox(
            width: size,
            height: size,
            child: CustomNetworkImage(
              effectiveImageUrl!,               // supports http(s)/gs://
              fit: BoxFit.cover,
              fallBackEnabled: false
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: _placeholder(radius),
    );
  }

  Widget _placeholder(double radius) {
    if (!showOnlyInitials) {
      return Center(child: Icon(profileIcon, size: radius, color: white));
    }
    final value = (initials ?? '').trim();
    final safe = value.isEmpty
        ? ''
        : value.split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();
    return Center(child: Text(safe, style: Styles.boldText, textAlign: TextAlign.center));
  }
}
