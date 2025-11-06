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
}
