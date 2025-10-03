import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // Ask permission (iOS, Android 13+)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // iOS: show heads-up while foreground
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    // Get token (for debugging and optional storage)
    final token = await _fcm.getToken();
    debugPrint('FCM token: $token');

    // Subscribe to a simple topic we’ll use in the function
    await _fcm.subscribeToTopic('all');

    // Optional: keep a copy under the user for targeted sends later
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('fcm_tokens')
            .doc(token)
            .set({
          'token': token,
          'platform': Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other'),
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}

    // Debug logs for foreground / when user taps a notification
    FirebaseMessaging.onMessage.listen((m) {
      debugPrint('onMessage: title=${m.notification?.title}, body=${m.notification?.body}, data=${m.data}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      debugPrint('onMessageOpenedApp: data=${m.data}');
    });

    // Re-subscribe on token refresh
    _fcm.onTokenRefresh.listen((_) async {
      await _fcm.subscribeToTopic('all');
    });
  }
}
