// lib/features/navigation/models/nav_models.dart
import 'package:nightowlcode/shared/utility/lat_lng.dart';

class NavStep {
  final String instruction;
  final LatLng location; // where the maneuver happens
  const NavStep({required this.instruction, required this.location});
}

class NavRoute {
  final List<LatLng> points; // polyline path
  final List<NavStep> steps; // ordered maneuvers
  final double distanceMeters; // total
  final double durationSeconds; // total
  const NavRoute({
    required this.points,
    required this.steps,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  bool get isEmpty => points.isEmpty;
}
