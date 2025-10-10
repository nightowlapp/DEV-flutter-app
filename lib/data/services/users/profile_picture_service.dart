import 'dart:typed_data';
import 'dart:ui' as ui
    show Image, ImageByteFormat, Codec, FrameInfo, instantiateImageCodec;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../firestore_paths.dart';
import '../media_existence.dart';

class ProfilePictureUploadResult {
  final String storagePath;
  final String downloadUrl;
  final int versionMillis;
  final int width;
  final int height;
  final int bytes;
  const ProfilePictureUploadResult({
    required this.storagePath,
    required this.downloadUrl,
    required this.versionMillis,
    required this.width,
    required this.height,
    required this.bytes,
  });
}

class ProfilePictureService {
  ProfilePictureService(this._storage, {MediaExistence? mediaExistence})
      : _media = mediaExistence;

  final FirebaseStorage _storage;
  final MediaExistence? _media;

  /// Always uploads WebP to:
  ///   user_images/<uid>/profile_picture.webp
  Future<ProfilePictureUploadResult> uploadProfileWebp({
    required String uid,
    required Uint8List original,
    int maxDim = 1024,
    int webpQuality = 80,
    bool archivePrevious = true,
  }) async {
    final canonicalPath =
        StoragePaths.userImage(uid, '${StoragePaths.profilePicture}.webp');
    final canonicalRef = _storage.ref().child(canonicalPath);

    if (archivePrevious) {
      await _archiveIfExists(
        rootRef: _storage.ref(),
        canonicalRef: canonicalRef,
        uid: uid,
      );
    }

    final tr = await _transcodeToWebp(
      original,
      maxDim: maxDim,
      quality: webpQuality,
    );

    await canonicalRef.putData(
      tr.bytes,
      SettableMetadata(
        contentType: 'image/webp',
        cacheControl: 'public, max-age=31536000, immutable',
      ),
    );

    final baseUrl = await canonicalRef.getDownloadURL();
    final v = DateTime.now().millisecondsSinceEpoch;
    final versioned = baseUrl.contains('?') ? '$baseUrl&v=$v' : '$baseUrl?v=$v';

    try {
      await _media?.invalidate(canonicalPath);
      await _media?.invalidate(baseUrl);
      await _media?.invalidate(versioned);
    } catch (_) {}

    return ProfilePictureUploadResult(
      storagePath: canonicalPath,
      downloadUrl: versioned,
      versionMillis: v,
      width: tr.width,
      height: tr.height,
      bytes: tr.bytes.length,
    );
  }

  Future<void> _archiveIfExists({
    required Reference rootRef,
    required Reference canonicalRef,
    required String uid,
  }) async {
    try {
      await canonicalRef.getMetadata(); // throws if not found
      final old = await canonicalRef.getData();
      if (old == null || old.isEmpty) return;

      final stamp = _fmt(DateTime.now());
      final archivePath =
          '${StoragePaths.userImages}/$uid/previous_profile_pictures/profile_picture_$stamp.webp';
      await rootRef
          .child(archivePath)
          .putData(old, SettableMetadata(contentType: 'image/webp'));
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return;
      rethrow;
    }
  }

  String _fmt(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}_${two(dt.hour)}-${two(dt.minute)}-${two(dt.second)}';
  }
}

class _TranscodeResult {
  final Uint8List bytes;
  final int width;
  final int height;
  _TranscodeResult(this.bytes, this.width, this.height);
}

extension _Transcode on ProfilePictureService {
  Future<_TranscodeResult> _transcodeToWebp(
    Uint8List original, {
    required int maxDim,
    required int quality,
  }) async {
    // Decode only to get original dimensions
    final origUi = await _decodeUiImage(original);
    final ow = origUi.width, oh = origUi.height;

    int? targetW, targetH;
    final longest = ow >= oh ? ow : oh;
    if (longest > maxDim) {
      final scale = maxDim / longest;
      targetW = (ow * scale).round();
      targetH = (oh * scale).round();
    }

    try {
      // Use flutter_image_compress to produce WebP
      final out = await FlutterImageCompress.compressWithList(
        original,
        format: CompressFormat.webp,
        quality: quality.clamp(0, 100),
        minWidth: targetW!,
        minHeight: targetH!,
        keepExif: false,
      );

      if (out.isEmpty) {
        throw UnsupportedError('WebP encoding returned empty data.');
      }

      final uiAfter = await _decodeUiImage(Uint8List.fromList(out));
      return _TranscodeResult(
          Uint8List.fromList(out), uiAfter.width, uiAfter.height);
    } on MissingPluginException {
      // Plugin not registered on this build
      throw UnsupportedError(
        'WebP encoder is not available on this build '
        '(flutter_image_compress not registered). '
        'Perform a full rebuild and ensure platform support.',
      );
    }
  }

  Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }
}
