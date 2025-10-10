// lib/data/providers/users/my_visit_sessions_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nightowlcode/data/firestore_paths.dart';

import '../../../models/users/visit_session.dart';
import '../other_providers.dart'; // firestoreProvider, firebaseAuthProvider

final myVisitSessionsProvider = StreamProvider<List<VisitSession>>((ref) {
  final db = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final uid = auth.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  final col = db
      .collection(DocumentPaths.users)
      .doc(uid)
      .collection(DocumentPaths.visits);
  return col
      .orderBy('entered_at', descending: true)
      .limit(1000)
      .snapshots()
      .map((s) => s.docs.map((d) => VisitSession.fromSnap(d)).toList());
});
