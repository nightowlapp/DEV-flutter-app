// lib/data/repositories/users/feedback_repository.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nightowlcode/data/repositories/users/role_repository.dart';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../firestore_paths/firestore_paths.dart'; // has FeedbackDocumentPaths, VenueDocumentPaths, FirestoreFields

class FeedbackRepository {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseStorage get _storage => FirebaseStorage.instance;

  static User get _requireUser {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return user;
  }

  static DocumentReference<Map<String, dynamic>> _userFeedbackRoot(String uid) {
    return _db.doc(FeedbackDocumentPaths.doc(uid));
  }

  // ---------------------------------------------------------------------------
  // App feedback: feedback/{uid}/app_feedback/{category}/{category}/{autoId}
  // ---------------------------------------------------------------------------
  static Future<void> submitAppFeedback({
    required String text,
    required String category,
  }) async {
    final user = _requireUser;

    final feedbackDoc = _userFeedbackRoot(user.uid)
        .collection(FeedbackDocumentPaths.appFeedback)
        .doc(category) // TODO smarter
        .collection(category) // collection named after category
        .doc(); // auto-id

    await feedbackDoc.set({
      FeedbackDocumentPaths.message: text,
      FeedbackDocumentPaths.createdAt: FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // Venue feedback: feedback/{uid}/venue_feedback/{venueId}/{category}/{autoId}
  // (legacy helper – still usable for very simple cases)
  // ---------------------------------------------------------------------------
  static Future<void> submitVenueFeedback({
    required String venueId,
    required String category, // e.g. "wrong_name"
    String message = '',
  }) async {
    final user = _requireUser;

    final doc = _userFeedbackRoot(user.uid)
        .collection(FeedbackDocumentPaths.venueFeedback)
        .doc(venueId)
        .collection(category)
        .doc();

    await doc.set({
      FeedbackDocumentPaths.message: message,
      FeedbackDocumentPaths.createdAt: FieldValue.serverTimestamp(),
      FeedbackDocumentPaths.venueId: venueId,
      FeedbackDocumentPaths.category: category,
      // roles / user meta can also be centralized later
    });
  }

  // ---------------------------------------------------------------------------
  // NEW: structured venue feedback flow
  // - create stub once (on first click) → returns docId
  // - later updates merge into same doc (message, suggested_age, etc.)
  // ---------------------------------------------------------------------------

  /// Create a stub feedback doc for a given venue + category.
  /// Used when the user first taps an edit option.
  ///
  /// Returns the newly created docId so the UI can update it later.
  static Future<String> createVenueFeedbackStub({
    required String venueId,
    required String category,
    Map<String, dynamic>? extraFields,
  }) async {
    final user = _requireUser;

    final col = _userFeedbackRoot(user.uid)
        .collection(FeedbackDocumentPaths.venueFeedback)
        .doc(venueId)
        .collection(category);

    final docRef = col.doc(); // auto-id

    await docRef.set({
      FeedbackDocumentPaths.message: '',
      FeedbackDocumentPaths.createdAt: FieldValue.serverTimestamp(),
      // FeedbackDocumentPaths.venueId: venueId, // not needed.
      FeedbackDocumentPaths.category: category,
      if (extraFields != null) ...extraFields,
    });

    return docRef.id;
  }

  /// Merge updates into an existing feedback doc (same user / venue / category / docId).
  /// Used when user adds details after the initial click.
  static Future<void> updateVenueFeedbackDetails({
    required String venueId,
    required String category,
    required String feedbackId,
    String? message,
    int? suggestedAge, // only used for age_restriction currently
    Map<String, dynamic>? extraFields,
  }) async {
    final user = _requireUser;

    final docRef = _userFeedbackRoot(user.uid)
        .collection(FeedbackDocumentPaths.venueFeedback)
        .doc(venueId)
        .collection(category)
        .doc(feedbackId);

    final data = <String, dynamic>{
      if (message != null) FeedbackDocumentPaths.message: message,
      if (suggestedAge != null) 'suggested_age': suggestedAge,
      if (extraFields != null) ...extraFields,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };

    await docRef.set(data, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // NEW: Tag suggestions:
  // feedback/{uid}/venue_feedback/{venueId}/tags/{autoId}
  // ---------------------------------------------------------------------------

  static Future<void> submitVenueTagSuggestion({
    required String venueId,
    required String tagId,
    required bool isAdmin,
    String? message,
    List<String> conflictingTagIds = const <String>[],
  }) async {
    final user = _requireUser;

    final tagsCol = _userFeedbackRoot(user.uid)
        .collection(FeedbackDocumentPaths.venueFeedback)
        .doc(venueId)
        .collection(FeedbackDocumentPaths.venueTags);

    final suggestionRef = tagsCol.doc(); // auto-id

    if (!isAdmin) {
      // Normal user: just record suggestion, not applied yet
      await suggestionRef.set({
        FeedbackDocumentPaths.venueId: venueId,
        FeedbackDocumentPaths.tagId: tagId,
        FeedbackDocumentPaths.message: message,
        FeedbackDocumentPaths.isApplied: false,
        FeedbackDocumentPaths.createdAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    // Admin: record suggestion + immediately add tag to venue.tag_ids
    await _db.runTransaction((tx) async {
      // 1) suggestion doc
      tx.set(suggestionRef, {
        FeedbackDocumentPaths.venueId: venueId,
        FeedbackDocumentPaths.tagId: tagId,
        FeedbackDocumentPaths.message: message,
        FeedbackDocumentPaths.isApplied: true,
        FeedbackDocumentPaths.createdAt: FieldValue.serverTimestamp(),
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      });

      // 2) update venue tags atomically
      final venueRef = _db.doc(VenueDocumentPaths.doc(venueId));

      // First remove conflicting tags (e.g. old venue_type / smoking_policy)
      if (conflictingTagIds.isNotEmpty) {
        tx.update(venueRef, {
          VenueDocumentPaths.tagIds:
              FieldValue.arrayRemove(conflictingTagIds.toSet().toList()),
        });
      }

      // Then add the new one
      tx.update(venueRef, {
        VenueDocumentPaths.tagIds: FieldValue.arrayUnion(<String>[tagId]),
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Crash reports:
  // feedback/{uid}/crashes/{venueId}/{errorString}/{autoId}
  // ---------------------------------------------------------------------------
  static Future<void> submitCrashReport({
    required String venueId,
    required Error error,
    String message = '',
  }) async {
    final user = _requireUser;

    final errorKey = error.toString(); // you may want to normalize this later

    final doc = _userFeedbackRoot(user.uid)
        .collection(FeedbackDocumentPaths.crashes)
        .doc(venueId)
        .collection(errorKey)
        .doc();

    await doc.set({
      FeedbackDocumentPaths.message: message,
      FeedbackDocumentPaths.createdAt: FieldValue.serverTimestamp(),
      FeedbackDocumentPaths.error: error.toString(), // avoid raw Error
      FeedbackDocumentPaths.errorString: error.toString(),
    });
  }

  static Future<({String url, DateTime uploadedAt})> uploadOfferImage({
    required String venueId,
    required String feedbackId,
    required File file,
  }) async {
    final user = _requireUser;

    final uploadedAt = DateTime.now();
    final ts = uploadedAt.millisecondsSinceEpoch;

    // 1) Read original bytes
    final Uint8List originalBytes = await file.readAsBytes();

    // 2) Compress & re-encode as WebP
    final Uint8List webpBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      format: CompressFormat.webp,
      quality: 80,
    );

    // 3) Path includes feedbackId → easy 1:1 mapping doc <-> file
    final path =
        '${StoragePaths.userImages}/${user.uid}/${StoragePaths.venueFeedback}/'
        '$venueId/${StoragePaths.offerImages}/$feedbackId-$ts.webp';

    final ref = _storage.ref().child(path);

    // 4) Upload WebP bytes with correct contentType
    await ref.putData(
      webpBytes,
      SettableMetadata(contentType: 'image/webp'),
    );

    // 5) Download URL
    final url = await ref.getDownloadURL();

    return (url: url, uploadedAt: uploadedAt);
  }

  static Future<String> uploadMoodImage({
    required String venueId,
    required File file,
  }) async {
    final user = _requireUser;

    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch;

    // 1) Read original bytes (likely JPEG/HEIC from camera)
    final Uint8List originalBytes = await file.readAsBytes();

    // 2) Compress & re-encode as WebP
    final Uint8List webpBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      format: CompressFormat.webp,
      quality: 80,
    );

    // 3) Storage path for mood images
    final path =
        '${StoragePaths.userImages}/${user.uid}/${StoragePaths.venueFeedback}/$venueId/${StoragePaths.moodImages}/$ts.webp';
    final ref = _storage.ref().child(path);

    // 4) Upload WebP bytes with correct contentType
    await ref.putData(
      webpBytes,
      SettableMetadata(contentType: 'image/webp'),
    );

    // 5) Get download URL
    final url = await ref.getDownloadURL();

    // 6) Append to a venue_media doc for this venue
    //    (adjust collection/field names to match your schema if needed)
    // final mediaRef = _db.collection('venue_media').doc(venueId);
    // await mediaRef.set({
    //   'mood_image_urls': FieldValue.arrayUnion(<String>[url]),
    //   FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    // }, SetOptions(merge: true));

    return url;
  }

  /// Generic crash report:
  /// feedback/{uid}/crashes/app/{errorKey}/{autoId}
  static Future<void> submitCrashReportGeneric({
    required Object error,
    StackTrace? stackTrace,
    String message = '',
    String venueId = 'app',
    String? route,
    Map<String, dynamic>? extraFields,
  }) async {
    final user = _requireUser;
    final info = await _packageInfo();

    final errorString = error.toString();
    final errorKey = _safeErrorKey(errorString);

    final doc = _userFeedbackRoot(user.uid)
        .collection(FeedbackDocumentPaths.crashes)
        .doc(venueId)
        .collection(errorKey)
        .doc();

    await doc.set({
      FeedbackDocumentPaths.createdAt: FieldValue.serverTimestamp(),
      FeedbackDocumentPaths.message: message,
      FeedbackDocumentPaths.error: errorString,
      FeedbackDocumentPaths.errorString: errorString,
      'stackTrace': stackTrace?.toString(),
      'route': route,
      'app': {
        'packageName': info.packageName,
        'version': info.version,
        'buildNumber': info.buildNumber,
      },
      'device': {
        'os': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
      },
      if (extraFields != null) ...extraFields,
    });
  }

  // ---- PackageInfo cache (avoid re-loading on every error) ----
  static PackageInfo? _cachedPackageInfo;
  static Future<PackageInfo> _packageInfo() async {
    return _cachedPackageInfo ??= await PackageInfo.fromPlatform();
  }

  // ---- Safe key for Firestore collection names ----
  // Your old code uses error.toString() as a collection name (can break if it contains '/').
  static String _safeErrorKey(String input) {
    // Stable hash-like key but readable-ish
    final normalized = input.trim().toLowerCase();
    final hash = _fnv1a64(normalized);
    return 'e_$hash';
  }


  static String _fnv1a64(String s) {
    const int fnvPrime = 1099511628211;
    const int offsetBasis = 1469598103934665603;

    int hash = offsetBasis;
    for (final codeUnit in s.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}
