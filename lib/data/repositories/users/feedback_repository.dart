import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../firestore_paths.dart';

class FeedbackRepository {
  static Future<void> submitAppFeedback({
    required String text,
    required String category,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    final feedbackDoc = FirebaseFirestore.instance
        .collection(DocumentPaths.feedback)
        .doc(user.uid)
        .collection(DocumentPaths.appFeedback)
        .doc(category) //TODO smarter.
        .collection(category) // collection named after category
        .doc(); // auto-id

    await feedbackDoc.set({
      'message': text,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// New: venue feedback at:
  /// feedback/{uid}/venue_feedback/{venueId}/{category}/{autoId}
  static Future<void> submitVenueFeedback({
    required String venueId,
    required String category, // e.g. "wrong_name"
    String message = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    final doc = FirebaseFirestore.instance
        .collection(DocumentPaths.feedback)
        .doc(user.uid)
        .collection(DocumentPaths.venueFeedback)
        .doc(venueId)
        .collection(category)
        .doc();

    await doc.set({
      'message': message,
      'created_at': FieldValue.serverTimestamp(),
      'venue_id': venueId,
      'category': category,
      // 'roles': ,
    });
  }
}
