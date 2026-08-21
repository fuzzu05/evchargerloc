import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/nav_step.dart';

/// Holds the full result from the Google Directions API.
class DirectionsResult {
  final List<NavStep> steps;
  final List<LatLng> polylinePoints;
  final String totalDuration; // e.g. "15 mins"
  final String totalDistance; // e.g. "3.2 km"
  final int totalDurationSeconds;
  final int totalDistanceMeters;

  DirectionsResult({
    required this.steps,
    required this.polylinePoints,
    required this.totalDuration,
    required this.totalDistance,
    required this.totalDurationSeconds,
    required this.totalDistanceMeters,
  });
}

class DirectionsService {
  static const String _apiKey = 'AIzaSyAbeI-P_j1sXfgOomAH6tMGUbwuW5OwwPs';
  static final PolylinePoints _polylinePoints = PolylinePoints();

  /// Strips HTML tags and unescapes common HTML entities from Google's html_instructions.
  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Fetches full turn-by-turn directions from [origin] to [destination].
  /// Returns null if the request fails or no routes are found.
  static Future<DirectionsResult?> getDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&departure_time=now'
      '&traffic_model=best_guess'
      '&key=$_apiKey',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        debugPrint('Directions API HTTP error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        debugPrint('Directions API status: ${data['status']}');
        return null;
      }

      final route = data['routes'][0] as Map<String, dynamic>;
      final leg = route['legs'][0] as Map<String, dynamic>;
      final stepsJson = leg['steps'] as List<dynamic>;

      // Parse each step into a NavStep
      final steps = stepsJson.map((step) {
        final s = step as Map<String, dynamic>;
        final htmlInstruction = s['html_instructions'] as String? ?? '';
        final endLoc = s['end_location'] as Map<String, dynamic>;
        return NavStep(
          instruction: _stripHtml(htmlInstruction),
          distanceMeters: (s['distance']?['value'] as int?) ?? 0,
          endLocation: LatLng(
            (endLoc['lat'] as num).toDouble(),
            (endLoc['lng'] as num).toDouble(),
          ),
          maneuver: s['maneuver'] as String? ?? 'straight',
        );
      }).toList();

      // Decode the full route polyline
      final encodedPoly = route['overview_polyline']['points'] as String;
      final decoded = _polylinePoints.decodePolyline(encodedPoly);
      final latLngs =
          decoded.map((p) => LatLng(p.latitude, p.longitude)).toList();

      return DirectionsResult(
        steps: steps,
        polylinePoints: latLngs,
        totalDuration: leg['duration']['text'] as String,
        totalDistance: leg['distance']['text'] as String,
        totalDurationSeconds: (leg['duration']['value'] as int?) ?? 0,
        totalDistanceMeters: (leg['distance']['value'] as int?) ?? 0,
      );
    } catch (e) {
      debugPrint('DirectionsService error: $e');
      return null;
    }
  }
}
