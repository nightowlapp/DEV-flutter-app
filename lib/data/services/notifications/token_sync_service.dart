// lib/data/services/notifications/token_sync_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nightowlcode/data/firestore_paths/firestore_paths.dart';

class TokenSyncService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> syncCurrentToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final userSnap =
        await _db.collection(FirestoreCollections.users).doc(uid).get();
    final user = userSnap.data() ?? {};

    final gender = ((user['gender'] as String?) ?? 'other').toLowerCase();
    final country =
        ((user['home_country_code'] as String?) ?? 'dk').toLowerCase();

    final birth =
        _asDateTime(user['birth_date']); // Timestamp | String | DateTime | null
    final ageBucket = _computeAgeBucket(birth); // "18".."34", "35+", "all"

    final ref = _db
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(UserDocumentPaths.fcmTokens)
        .doc(token);

    await ref.set({
      'token': token,
      'platform':
          Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other'),
      'country_code': country, // lowercase
      'gender': gender, // lowercase
      'age_bucket': ageBucket, // string
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  String _computeAgeBucket(DateTime? birth) {
    if (birth == null) return 'all';
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    if (age <= 18) return '18';
    if (age >= 35) return '35+';
    return age.toString(); // "19" || "34" ...
  }
}
