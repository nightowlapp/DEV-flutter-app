// lib/features/location/location_status.dart
import 'package:geolocator/geolocator.dart';

class LocationStatus {
  final bool servicesEnabled;
  final LocationPermission permission;

  const LocationStatus({
    required this.servicesEnabled,
    required this.permission,
  });

  const LocationStatus.initial()
      : servicesEnabled = false,
        permission = LocationPermission.denied;

  bool get ready =>
      servicesEnabled &&
      (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always);

  bool get isDenied =>
      permission == LocationPermission.denied ||
      permission == LocationPermission.unableToDetermine;

  bool get isDeniedForever => permission == LocationPermission.deniedForever;

  LocationStatus copyWith({
    bool? servicesEnabled,
    LocationPermission? permission,
  }) =>
      LocationStatus(
        servicesEnabled: servicesEnabled ?? this.servicesEnabled,
        permission: permission ?? this.permission,
      );
}
