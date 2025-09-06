// lib/core/storage/profile_image_service.dart
import 'dart:typed_data';
import 'dart:ui' as ui
    show Image, ImageByteFormat, Codec, FrameInfo, instantiateImageCodec;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

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

  Future<ProfilePictureUploadResult> uploadProfileWebp({
    required String uid,
    required Uint8List original,
    int maxDim = 1024,
    int webpQuality = 80,
    bool archivePrevious = true,
  }) async {
    final canonicalPath = StoragePaths.userImage(uid, '${StoragePaths.profilePicture}.webp');
    final canonicalRef = _storage.ref().child(canonicalPath);

    // Archive existing (best-effort)
    if (archivePrevious) {
      await _archiveIfExists(
        rootRef: _storage.ref(),
        canonicalRef: canonicalRef,
        uid: uid,
      );
    }

    // Transcode -> WebP
    final tr = await _transcodeToWebp(
      original,
      maxDim: maxDim,
        quality: webpQuality
    );

    // Upload
    await canonicalRef.putData(
      tr.bytes,
      SettableMetadata(
        contentType: 'image/webp',
        cacheControl: 'public, max-age=31536000, immutable',
      ),
    );

    // Versioned URL
    final baseUrl = await canonicalRef.getDownloadURL();
    final v = DateTime.now().millisecondsSinceEpoch;
    final versioned = baseUrl.contains('?') ? '$baseUrl&v=$v' : '$baseUrl?v=$v';

    // Invalidate local existence cache if wired in
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
    img.Image? decoded = img.decodeImage(original);

    // Fallback: decode via dart:ui for formats the `image` package can't parse.
    if (decoded == null) {
      try {
        final uiImage = await _decodeUiImage(original);
        final bd = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (bd != null) {
          decoded = img.Image.fromBytes(
            width: uiImage.width,
            height: uiImage.height,
            bytes: bd.buffer,          // ByteBuffer ✔ (not Uint8List)
            rowStride: uiImage.width * 4,
            numChannels: 4,
            order: img.ChannelOrder.rgba,
            format: img.Format.uint8,
          );
        }
      } catch (_) {}
    }

    if (decoded == null) {
      throw Exception('Unsupported or corrupt image. Please choose a different file.');
    }

    // Resize to cap longest side
    final w = decoded.width, h = decoded.height;
    final scale = (w >= h) ? (maxDim / w) : (maxDim / h);
    final processed = (scale < 1.0)
        ? img.copyResize(
      decoded,
      width: (w * scale).round(),
      height: (h * scale).round(),
      interpolation: img.Interpolation.average,
    )
        : decoded;

    // ✅ Correct order for image ^4.5.4:
    // encodeNamedImage(String name, Image image, {quality, ...})
    final encoded = img.encodeNamedImage('${StoragePaths.profilePicture}.webp', processed,);
    if (encoded == null) {
      throw UnsupportedError(
        'WebP encoding not available in the linked `image` package. '
            'Ensure you are on image ^4.5.4+.',
      );
    }

    return _TranscodeResult(Uint8List.fromList(encoded), processed.width, processed.height);
  }

  Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }
}
