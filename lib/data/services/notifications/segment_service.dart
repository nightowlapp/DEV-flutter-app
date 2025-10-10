import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nightowlcode/data/services/notifications/segment_rule.dart';
import 'package:nightowlcode/data/services/notifications/segment_rules.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'device_context.dart';

class SegmentService {
  static const _rcParam = 'segment_rules_json';

  Future<List<String>> applySubscriptions({bool forceRefresh = false}) async {
    final rc = FirebaseRemoteConfig.instance;
    if (forceRefresh) {
      await rc.fetchAndActivate();
    } else {
      // gentle fetch to keep fast
      unawaited(rc.fetchAndActivate());
    }

    final device = await DeviceContext.build();
    final rulesJson = rc.getString(_rcParam);
    final rules = rulesJson.trim().isEmpty
        ? _fallbackRules()
        : SegmentRules.fromJsonString(rulesJson);

    final topics = rules.matchingTopics(device);

    // Ensure we only subscribe to what we need (idempotent)
    final messaging = FirebaseMessaging.instance;
    // No official API to list current topic subs; we keep it simple and just call subscribe
    for (final t in topics) {
      await messaging.subscribeToTopic(t);
    }

    // Optional: unsubscribe from stale topics if you maintain a "managed" namespace
    // (e.g., only topics starting with "seg_"). We skip for brevity.

    return topics;
  }

  SegmentRules _fallbackRules() {
    // Works even if you never set up Remote Config yet
    return SegmentRules(rules: [
      SegmentRule(name: 'all', topics: ['all']),
      if (Platform.isIOS) SegmentRule(name: 'ios', topics: ['ios']),
      if (Platform.isAndroid) SegmentRule(name: 'android', topics: ['android']),
      // add a region/topic example you may use server-side
      // SegmentRule(name: 'eu', topics: ['region_eu'], ifLocalePrefix: 'en') // demo
    ]);
  }
}
