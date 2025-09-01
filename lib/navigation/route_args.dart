// lib/navigation/route_args.dart
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/data/services/media_existence.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

class VenueMainArgs {
  final Venue venue;
  final VenueMediaHealth? media;
  final LatLng? userLoc;

  const VenueMainArgs({
    required this.venue,
    this.media,
    this.userLoc,
  });
}
