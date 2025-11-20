// lib/data/providers/users/my_visit_sessions_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/firestore_paths/firestore_paths.dart';

import '../../../models/users/visit_session.dart';
import '../other_providers.dart'; // firestoreProvider, firebaseAuthProvider

final myVisitSessionsProvider = StreamProvider<List<VisitSession>>((ref) {
  final db = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final uid = auth.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  final col =
  db.collection(VisitDocumentPaths.collectionForUser(uid));

  return col
      .orderBy(VisitDocumentPaths.enteredAt, descending: true)
      .limit(1000)
      .snapshots()
      .map((s) => s.docs.map(VisitSession.fromSnap).toList());
});
