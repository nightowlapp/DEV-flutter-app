import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';

import '../../../data/other_providers.dart';
import '../../../shared/constants/styles.dart'; // authUserProvider, profilePictureServiceProvider, userRepositoryProvider

// ---- Public APIs ------------------------------------------------------------

// Keep the old signature, but immediately convert ref -> container.
Future<void> changeProfilePicture(BuildContext context, WidgetRef ref) async {
  final container = ProviderScope.containerOf(context, listen: false);
  await changeProfilePictureWithContainer(context, container);
}

/// Public, safe API you can call after popping routes/dialogs.
Future<void> changeProfilePictureWithContainer(
    BuildContext context,
    ProviderContainer container, {
      ImageSource? source, // if null -> chooser sheet
    }) async {
  final user = container.read(authUserProvider).maybeWhen(
    data: (u) => u,
    orElse: () => null,
  );
  if (user == null) {
    _snack(context, 'You must be signed in to change your photo.');
    return;
  }

  final src = source ?? await _chooseSource(context);
  if (src == null) return;

  final picked = await ImagePicker().pickImage(
    source: src,
    preferredCameraDevice: CameraDevice.front,
    requestFullMetadata: true,
    maxWidth: 4000,
    maxHeight: 4000,
  );
  if (picked == null) return;

  final Uint8List bytes = await picked.readAsBytes();

  final svc  = container.read(profilePictureServiceProvider);
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
    _snack(context, 'Profile photo updated.');
  } catch (e) {
    _snack(context, 'Failed to update photo. $e');
  }
}

// ---- Internals --------------------------------------------------------------

Future<ImageSource?> _chooseSource(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: black,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, size: iconSizeDefault, color: owlOrange,),
            title: Text('Take photo',style: Styles.basicText,),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, size: iconSizeDefault, color: owlOrange,),
            title: Text('Choose from gallery',style: Styles.basicText,),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
