import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

@immutable
class PartyStatusEntry {
  final String id; // Firestore doc id (entry)
  final PartyStatusTypes partyStatus;
  final PartyStatusChange partyStatusChange;
  final DateTime createdAt;

  // Optional location snapshot
  final GeoPoint? location;
  final double? accuracy;

  const PartyStatusEntry({
    required this.id,
    required this.partyStatus,
    required this.partyStatusChange,
    required this.createdAt,
    this.location,
    this.accuracy,
  });

  Map<String, dynamic> toJson() => {
        'party_status': partyStatus.name,
        'change': partyStatusChange.name,
        'created_at': Timestamp.fromDate(createdAt),
        if (location != null) 'location': location,
        if (accuracy != null) 'accuracy': accuracy,
      };

  static PartyStatusEntry fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data()!;
    final ts = d['created_at'];
    final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
    return PartyStatusEntry(
      id: snap.id,
      partyStatus: PartyStatusTypes.values.firstWhere(
        (e) => e.name == (d['party_status'] as String? ?? ''),
        orElse: () => PartyStatusTypes.still_planning,
      ),
      partyStatusChange: PartyStatusChange.values.firstWhere(
        (e) => e.name == (d['change'] as String? ?? ''),
        orElse: () => PartyStatusChange.manual,
      ),
      createdAt: dt,
      location: d['location'] as GeoPoint?,
      accuracy: (d['accuracy'] as num?)?.toDouble(),
    );
  }

  /// Helper to map geolocator [Position] → fields we store.
  static (GeoPoint?, double?) fromPosition(Position? p) {
    if (p == null) return (null, null);
    return (GeoPoint(p.latitude, p.longitude), p.accuracy);
  }
}

@immutable
class CurrentPartyStatus {
  final PartyStatusTypes status;
  const CurrentPartyStatus(this.status);
}
