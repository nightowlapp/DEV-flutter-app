import 'device_context.dart';

class SegmentRule {
  final String name;
  final List<String> topics;
  final String? ifPlatform;       // 'ios' | 'android' | null
  final String? ifLocalePrefix;   // e.g. 'en'
  final String? ifVersionGte;     // e.g. '1.2.0'

  SegmentRule({
    required this.name,
    required this.topics,
    this.ifPlatform,
    this.ifLocalePrefix,
    this.ifVersionGte,
  });

  factory SegmentRule.fromMap(Map<String, dynamic> m) {
    return SegmentRule(
      name: m['name'] as String? ?? 'rule',
      topics: (m['topics'] as List?)?.cast<String>().toList() ?? const [],
      ifPlatform: m['if']?['platform'] as String?,
      ifLocalePrefix: m['if']?['locale_prefix'] as String?,
      ifVersionGte: m['if']?['version_gte'] as String?,
    );
  }

  bool matches(DeviceContext ctx) {
    if (ifPlatform != null && ifPlatform != ctx.platform) return false;
    if (ifLocalePrefix != null && !ctx.locale.toLowerCase().startsWith(ifLocalePrefix!.toLowerCase())) return false;
    if (ifVersionGte != null && _compareVersions(ctx.version, ifVersionGte!) < 0) return false;
    return true;
  }

  // very small semantic version compare: returns -1,0,1
  int _compareVersions(String a, String b) {
    List<int> pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    while (pa.length < pb.length) pa.add(0);
    while (pb.length < pa.length) pb.add(0);
    for (int i = 0; i < pa.length; i++) {
      if (pa[i] != pb[i]) return pa[i] > pb[i] ? 1 : -1;
    }
    return 0;
  }
}