import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Represents a single step in a turn-by-turn navigation route.
class NavStep {
  final String instruction; // Clean text (HTML stripped)
  final int distanceMeters;
  final LatLng endLocation;
  final String maneuver; // e.g. 'turn-left', 'turn-right', 'straight', 'roundabout-right'

  const NavStep({
    required this.instruction,
    required this.distanceMeters,
    required this.endLocation,
    required this.maneuver,
  });

  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '$distanceMeters m';
  }
}
