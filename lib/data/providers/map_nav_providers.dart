// lib/features/map/presentation/map_nav_providers.dart
import 'dart:ffi';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';

final mapNavControllerProvider =
AutoDisposeNotifierProvider<MapNavController, MapNavCommand?>(
  MapNavController.new,
);

class MapNavCommand {
  final int id;
  final LatLng target;
  final double zoom;

  /// If true, MapScreen will open a popup after easing.
  final bool openPopup;

  /// Carry the venue so we can open immediately (no async lookup needed).
  final Venue? venue;

  const MapNavCommand({
    required this.id,
    required this.target,
    this.zoom = 16,
    this.openPopup = false,
    this.venue,
  });
}

class MapNavController extends AutoDisposeNotifier<MapNavCommand?> {
  int _seq = 0;

  @override
  MapNavCommand? build() => null;

  void flyTo(LatLng target, {double zoom = 16, bool openPopup = true}) {
    _seq++;
    state = MapNavCommand(
      id: _seq,
      target: target,
      zoom: zoom,
      openPopup: openPopup,
    );
  }

  void easeTo(LatLng target, {double zoom = 16, bool openPopup = true}){
    _seq++;
    state = MapNavCommand(
      id: _seq,
      target: target,
      zoom: zoom,
      openPopup: openPopup,
    );
  }

  void flyToVenue(Venue v, {double zoom = 16, bool openPopup = true}) {
    _seq++;
    state = MapNavCommand(
      id: _seq,
      target: v.entry,
      zoom: zoom,
      openPopup: openPopup,
      venue: v,
    );
  }
}
