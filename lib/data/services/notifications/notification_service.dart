import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nightowlcode/data/services/notifications/token_sync_service.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  factory NotificationService() => instance;
  final _fcm = FirebaseMessaging.instance;
  final _fln = FlutterLocalNotificationsPlugin();

  Future<void> init() async {

    await ensureNotifReady();

    // Ask permission (iOS, Android 13+)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // iOS: show heads-up while foreground
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    // Get token (for debugging and optional storage)
    final token = await _fcm.getToken();
    await TokenSyncService().syncCurrentToken();

    // Subscribe to a simple topic we’ll use in the function
    await _fcm.subscribeToTopic('all');

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // navigate using initial.data
    }

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
      final n = m.notification;
      if (n != null) {
        _fln.show(
          n.hashCode,
          n.title,
          n.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'nightowl_default',
              'General',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: m.data.isNotEmpty ? m.data.toString() : null,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      // debugPrint('onMessageOpenedApp: data=${m.data}');
    });

    // Re-subscribe on token refresh
    _fcm.onTokenRefresh.listen((_) async {
      await _fcm.subscribeToTopic('all');   // keep if you like a global topic
      await TokenSyncService().syncCurrentToken();
    });
  }

  Future<void> initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _fln.initialize(const InitializationSettings(android: android, iOS: ios));

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'nightowl_default', // MUST match strings.xml value
        'General',
        description: 'Default notifications for NightOwl',
        importance: Importance.high,
      );
      final androidPlugin = _fln.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);
    }
  }

  Future<void> ensureNotifReady() async {
    if (Platform.isAndroid) {
      final s = await Permission.notification.status;
      if (!s.isGranted) await Permission.notification.request();
    }
    // iOS already handled in NotificationService.init()
    final token = await FirebaseMessaging.instance.getToken();
  }
}
