import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../firestore_paths/firestore_paths.dart';

class FeedbackRepository {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

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
      FeedbackDocumentPaths.error: error.toString(),      // avoid raw Error
      FeedbackDocumentPaths.errorString: error.toString(),
    });
  }
}
