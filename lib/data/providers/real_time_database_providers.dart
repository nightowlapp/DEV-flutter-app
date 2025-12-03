import 'package:firebase_database/firebase_database.dart';
import 'package:nightowlcode/data/firestore_paths/firestore_paths.dart';

final DatabaseReference _liveCountsRoot =
    FirebaseDatabase.instance.ref(LiveCountDocumentPaths.collection);

// Stream all counts (Map<venueId, count>)
Stream<Map<String, int>> liveAllVenueCounts() {
  return _liveCountsRoot.onValue.map((event) {
    final value = event.snapshot.value;
    if (value is! Map) return <String, int>{};

    final out = <String, int>{};

    value.forEach((key, v) {
      if (key is! String) return;
      if (v is! Map) return;

      final m = v as Map;
      final raw = m[LiveCountDocumentPaths.count];

      // RTDB may store num, int, or even string; be defensive
      int parsed;
      if (raw is int) {
        parsed = raw;
      } else if (raw is num) {
        parsed = raw.toInt();
      } else if (raw is String) {
        parsed = int.tryParse(raw) ?? 0;
      } else {
        parsed = 0;
      }

      out[key] = parsed;
    });

    return out;
  });
}

// Per-venue count stream
Stream<int> liveVenueCount(String venueId) {
  final ref = FirebaseDatabase.instance.ref(
    '${LiveCountDocumentPaths.collection}/$venueId/${LiveCountDocumentPaths.count}',
  );

  return ref.onValue.map((event) {
    final v = event.snapshot.value;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  });
}
