import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nightowlcode/data/services/notifications/segment_service.dart';

class NotificationService {
  Future<void> init() async {
    // iOS permission
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true, announcement: false, badge: true, carPlay: false,
      criticalAlert: false, provisional: false, sound: true,
    );
    // print('Permission: ${settings.authorizationStatus}');

    // Token + refresh resubscribe
    await FirebaseMessaging.instance.getToken();
    FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      // Re-apply topics on token changes
      SegmentService().applySubscriptions();
    });

    // Apply segments on first launch
    await SegmentService().applySubscriptions();
  }
}