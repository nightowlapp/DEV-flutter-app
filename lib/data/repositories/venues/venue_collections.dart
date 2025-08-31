// lib/data/repositories/venues/venue_collections.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightowlcode/data/firestore_paths.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/data/repositories/venues/venue_converters.dart';

class VenueCollections {
  VenueCollections({FirebaseFirestore? db}) : db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore db;

  CollectionReference<Venue> get venues =>
      db.collection(DocumentPaths.venues).withConverter<Venue>(
        fromFirestore: (snap, _) => VenueFirestore.fromSnapshot(snap),
        toFirestore: (v,   _) => VenueFirestore.toMap(v),
      );
}
