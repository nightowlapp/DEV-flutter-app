import 'package:flutter/foundation.dart';

@immutable
class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  factory LatLng.fromJson(Map<String, dynamic> json) =>
      LatLng((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());
}
