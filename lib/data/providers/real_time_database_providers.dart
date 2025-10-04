import 'package:firebase_database/firebase_database.dart';
import 'package:nightowlcode/data/firestore_paths.dart';

final rtdb = FirebaseDatabase.instance.ref(DocumentPaths.liveCounts);

// stream all counts (map<venueId, {count, updatedAt}>)
Stream<Map<String, int>> liveAllVenueCounts() {
  return rtdb.onValue.map((event) {
    final data = (event.snapshot.value as Map?) ?? {};
    final out = <String, int>{};
    data.forEach((k, v) {
      final m = (v as Map?) ?? {};
      out[k as String] = (m[DocumentPaths.count] as int?) ?? 0;
    });
    return out;
  });
}

// or per venue
Stream<int> liveVenueCount(String venueId) =>
    FirebaseDatabase.instance.ref('${DocumentPaths.liveCounts}/$venueId/${DocumentPaths.count}')
        .onValue.map((e) => (e.snapshot.value as int?) ?? 0);

