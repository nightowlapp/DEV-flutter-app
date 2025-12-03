// lib/shared/reusable/ui/profile_picture_avatar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/utility/custom_network_image.dart';

import 'package:nightowlcode/data/providers/other_providers.dart'
    show authUserProvider;
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
    this.borderWidth = 1,
    this.backgroundColor,
    this.onTap,
    this.onLongPress,
    this.onAddImage,
    this.semanticLabel,
    this.showOnlyInitials = false,
    this.initials,
    this.disablePrompt = true,
    this.useAuthUserAsFallback = false, // 👈 NEW
  });

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
  final bool showOnlyInitials;
  final String? initials;
  final bool disablePrompt;

  /// If true, when [imageUrl] is null/empty we use the auth user's photo.
  /// If false, we just show the placeholder.
  final bool useAuthUserAsFallback;

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;

    return Consumer(
      builder: (context, ref, _) {
        final userAsync = ref.watch(authUserProvider);
        final userPhotoUrl = userAsync.maybeWhen(
          data: (u) => u?.profilePictureUrl,
          orElse: () => null,
        );

        final autoColor = ref.watch(partyStatusColorProvider);
        final effectiveBorderColor = borderColor ?? autoColor;
        final hasBorder =
            borderWidth > 0 && effectiveBorderColor != transparent;

        final effectiveImageUrl = (imageUrl?.trim().isNotEmpty == true)
            ? imageUrl
            : (useAuthUserAsFallback ? userPhotoUrl : null);

        Widget avatar = _buildAvatar(
          radius: radius,
          context: context,
          effectiveImageUrl: effectiveImageUrl,
        );

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
                await changeProfilePicture(context, ref);
              }
            },
            onLongPress: onLongPress,
            child: avatar,
          ),
        );

        if (hasBorder) {
          avatar = Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(borderWidth),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border:
                  Border.all(color: effectiveBorderColor, width: borderWidth),
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

    // 1) Explicit ImageProvider wins
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

    // 2) Otherwise, use the effective URL if present
    if (_hasCandidateImage(effectiveImageUrl)) {
      final url = effectiveImageUrl!.trim();
      return DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        child: ClipOval(
          child: SizedBox(
            width: size,
            height: size,
            child: CustomNetworkImage(
              url, // supports http(s)/gs://
              fit: BoxFit.cover,
              fallBackEnabled: false,
            ),
          ),
        ),
      );
    }

    // 3) Fallback: placeholder (icon or initials)
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
        : value
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w[0])
            .join()
            .toUpperCase();
    return Center(
      child: Text(
        safe,
        style: Styles.boldText,
        textAlign: TextAlign.center,
      ),
    );
  }
}
