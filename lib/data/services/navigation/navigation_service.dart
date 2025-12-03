// lib/features/navigation/services/navigation_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import '../../../models/navigation/nav_models.dart';
import '../../../shared/utility/utility.dart';

enum NavProfile { driving, walking, cycling }

extension on NavProfile {
  String get slug {
    switch (this) {
      case NavProfile.driving:
        return 'driving';
      case NavProfile.walking:
        return 'walking';
      case NavProfile.cycling:
        return 'cycling';
    }
  }
}

class NavigationService {
  final String accessToken;
  final http.Client _client;
  NavigationService({required this.accessToken, http.Client? client})
      : _client = client ?? http.Client();

  Future<NavRoute> route({
    required LatLng origin,
    required LatLng destination,
    NavProfile profile = NavProfile.walking, // <- default walking
    String? language, // e.g. 'en', 'da'
  }) async {
    final profileSlug = profile.slug; // 'driving' | 'walking' | 'cycling'
    final lang = (language ?? 'en').split('_').first;

    final uri = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/$profileSlug/'
      '${origin.lng},${origin.lat};${destination.lng},${destination.lat}'
      '?alternatives=false&geometries=polyline6&steps=true&overview=full'
      '&language=$lang'
      '&access_token=$accessToken',
    );

    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw StateError('Directions ${res.statusCode}: ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = (map['routes'] as List?) ?? const [];
    if (routes.isEmpty) {
      return const NavRoute(
          points: [], steps: [], distanceMeters: 0, durationSeconds: 0);
    }

    final r = routes.first as Map<String, dynamic>;
    final geometry = r['geometry'] as String;
    final points = Polyline6.decode(geometry);
    final legs = (r['legs'] as List).cast<Map<String, dynamic>>();

    final steps = <NavStep>[];
    for (final leg in legs) {
      for (final s in (leg['steps'] as List).cast<Map<String, dynamic>>()) {
        final man = (s['maneuver'] as Map<String, dynamic>);
        final loc = (man['location'] as List).cast<num>();
        final instr = (man['instruction'] as String?) ??
            '${man['type'] ?? ''} ${man['modifier'] ?? ''}';
        steps.add(NavStep(
          instruction: instr,
          location: LatLng(loc[1].toDouble(), loc[0].toDouble()),
        ));
      }
    }

    return NavRoute(
      points: points,
      steps: steps,
      distanceMeters: (r['distance'] as num).toDouble(),
      durationSeconds: (r['duration'] as num).toDouble(),
    );
  }

  // convenience wrappers if you like:
  Future<NavRoute> walkingRoute(
          {required LatLng origin, required LatLng destination}) =>
      route(
          origin: origin,
          destination: destination,
          profile: NavProfile.walking);

  Future<NavRoute> cyclingRoute(
          {required LatLng origin, required LatLng destination}) =>
      route(
          origin: origin,
          destination: destination,
          profile: NavProfile.cycling);

  Future<NavRoute> drivingRoute(
          {required LatLng origin, required LatLng destination}) =>
      route(
          origin: origin,
          destination: destination,
          profile: NavProfile.driving);
}
