// lib/data/services/live_location_publisher.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nightowlcode/data/firestore_paths.dart';

class LiveLocationPublisher {
  final _db = FirebaseFirestore.instance;
  StreamSubscription<Position>? _sub;
  Position? _lastSent;

  Future<void> start() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;
    }

    final settings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
    );

    await _sub?.cancel();
    _sub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((pos) async {
      if (!_shouldSend(pos)) return;
      _lastSent = pos;

      await _db.collection(DocumentPaths.locations).doc(uid).set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'accuracy': pos.accuracy,
        'heading': pos.heading,
        'speed': pos.speed,
        'timestamp': FieldValue.serverTimestamp(), // ✅ Timestamp
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

  Future<void> stop() async => _sub?.cancel();
}
