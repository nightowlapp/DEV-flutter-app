import 'dart:convert';

import 'package:nightowlcode/data/services/notifications/segment_rule.dart';

import 'device_context.dart';

class SegmentRules {
  final List<SegmentRule> rules;
  SegmentRules({required this.rules});

  factory SegmentRules.fromJsonString(String json) {
    final Map<String, dynamic> m = _tryDecode(json);
    final List<dynamic> list = (m['rules'] as List?) ?? const [];
    return SegmentRules(
      rules: list
          .map((e) => SegmentRule.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  List<String> matchingTopics(DeviceContext ctx) {
    final out = <String>{};
    for (final r in rules) {
      if (r.matches(ctx)) {
        out.addAll(r.topics);
      }
    }
    return out.toList()..sort();
  }

  static Map<String, dynamic> _tryDecode(String json) {
    try {
      return json.isEmpty ? {} : (jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return {};
    }
  }
}
