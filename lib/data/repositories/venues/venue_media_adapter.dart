// lib/models/venues/venue_media_adapter.dart
import 'package:nightowlcode/models/venues/venue.dart';
import '../../services/media_existence.dart';

/// Simple adapter so Venue can be used by VenueMediaService without mixing deps.
class VenueLikeAdapter implements VenueLike {
  final Venue v;
  const VenueLikeAdapter(this.v);

  @override
  String get id => v.id;

  @override
  String? get coverImageUrl => v.coverImageUrl; // path or URL

  @override
  String? get logoUrl => v.logoUrl;

  @override
  List<String> get moodImageUrls => v.moodImageUrls;
}
