// lib/data/services/live_location_publisher.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import 'package:nightowlcode/data/firestore_paths/firestore_paths.dart';
import 'package:nightowlcode/models/users/location_audience.dart';

class LiveLocationPublisher {
  final _db = FirebaseFirestore.instance;
  StreamSubscription<Position>? _sub;
  Position? _lastSent;

  LocationAudience _audience = LocationAudience.none;

  Future<void> setAudience(LocationAudience a) async {
    _audience = a;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _db.collection(FirestoreCollections.locations).doc(uid).set(
      {
        'audience': _audience.raw,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> start() async {
    //Todo needs to know when this fires. Should be correct location.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Already streaming
    if (_sub != null) return;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
    );

    await _sub?.cancel();
    _sub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((pos) async {
      if (!_shouldSend(pos)) return;
      _lastSent = pos;

      await _db.collection(FirestoreCollections.locations).doc(uid).set({
        'last_known_lat': pos.latitude,
        'last_known_lon': pos.longitude,
        'accuracy': pos.accuracy,
        'heading': pos.heading,
        'speed': pos.speed,
        'updated_at': FieldValue.serverTimestamp(),
        'audience': _audience.raw, // 👈 critical: who may see me
      }, SetOptions(merge: true));
    });
  }

  bool _shouldSend(Position p) {
    if (_lastSent == null) return true;
    final lastTs =
        _lastSent!.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
    final dt = (p.timestamp ?? DateTime.now()).difference(lastTs).inSeconds;
    final dist = Geolocator.distanceBetween(
      _lastSent!.latitude,
      _lastSent!.longitude,
      p.latitude,
      p.longitude,
    );
    return dt >= 10 || dist >= 30;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Optional: explicitly mark as not sharing
    await _db
        .collection(FirestoreCollections.locations)
        .doc(uid)
        .set({'audience': LocationAudience.none.raw}, SetOptions(merge: true));
  }
}
