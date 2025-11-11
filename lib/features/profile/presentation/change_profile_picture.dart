// lib/features/profile/presentation/change_profile_picture.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/styles.dart';

import '../../../data/providers/other_providers.dart';
import '../../../shared/constants/icons.dart';
import '../../../shared/reusable/ui/owl_snack.dart'; // authUserProvider, profilePictureServiceProvider, userRepositoryProvider

// ---- Public APIs ------------------------------------------------------------

Future<void> changeProfilePicture(BuildContext context, WidgetRef ref) async {
  final container = ProviderScope.containerOf(context, listen: false);
  await changeProfilePictureWithContainer(context, container);
}

Future<void> changeProfilePictureWithContainer(
  BuildContext context,
  ProviderContainer container, {
  ImageSource? source, // if null -> chooser sheet
}) async {
  // 🔑 Use a root context that survives popping sheets/dialogs
  final rootCtx = Navigator.of(context, rootNavigator: true).context;

  final user = container.read(authUserProvider).maybeWhen(
        data: (u) => u,
        orElse: () => null,
      );
  if (user == null) {
    OwlSnack.show(
      rootCtx,
      title: 'Sign in required',
      message: 'You must be signed in to change your photo.',
      variant: OwlSnackVariant.warning,
    );
    return;
  }

  final src = source ?? await _chooseSource(rootCtx);
  if (src == null) return; // user cancelled

  final picked = await ImagePicker().pickImage(
    source: src,
    preferredCameraDevice: CameraDevice.front,
    requestFullMetadata: true,
    maxWidth: 4000,
    maxHeight: 4000,
  );
  if (picked == null) return; // user cancelled

  final Uint8List bytes = await picked.readAsBytes();

  final svc = container.read(profilePictureServiceProvider);
  final repo = container.read(userRepositoryProvider);

  try {
    final result = await svc.uploadProfileWebp(
      uid: user.id,
      original: bytes,
      maxDim: 1024,
      webpQuality: 80,
      archivePrevious: true,
    );
    await repo.upsert(user.copyWith(profilePictureUrl: result.downloadUrl));
    OwlSnack.show(
      rootCtx,
      title: 'Profile Picture uploaded',
      message: 'Looking sharp! ✨',
      variant: OwlSnackVariant.success,
    );
  } on UnsupportedError catch (e) {
    OwlSnack.show(
      rootCtx,
      title: 'Failed to upload picture',
      message: e.message ?? e.toString(),
      variant: OwlSnackVariant.error,
    );
  } catch (e) {
    OwlSnack.show(
      rootCtx,
      title: 'Failed to upload picture',
      message: '$e',
      variant: OwlSnackVariant.error,
    );
  }
}

// ---- Internals --------------------------------------------------------------

Future<ImageSource?> _chooseSource(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context, // pass rootCtx from caller
    useRootNavigator: true, // show above dialogs
    backgroundColor: black,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              cameraIcon,
              size: iconSizeDefault,
              color: owlPurple,
            ),
            title: Text('Take photo', style: Styles.basicText), // TODO require permission to users photos of venues in the future.
            onTap: () =>
                Navigator.of(ctx, rootNavigator: true).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(
              photoLibraryIcon,
              size: iconSizeDefault,
              color: owlPurple,
            ),
            title: Text('Choose from gallery', style: Styles.basicText),
            onTap: () =>
                Navigator.of(ctx, rootNavigator: true).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}
