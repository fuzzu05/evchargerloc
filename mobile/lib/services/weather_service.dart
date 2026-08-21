import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Fetches real-time weather conditions from open-meteo.com (free, no API key needed).
class WeatherService {
  /// Returns a human-readable warning string if adverse weather is detected,
  /// or null if conditions are fine.
  static Future<String?> getWeatherWarning(double lat, double lng) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat'
      '&longitude=$lng'
      '&current=weather_code,precipitation,wind_speed_10m'
      '&forecast_days=1',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>;
      final weatherCode = (current['weather_code'] as num).toInt();
      final precipitation = (current['precipitation'] as num).toDouble();
      final windSpeed = (current['wind_speed_10m'] as num).toDouble();

      // WMO Weather codes:
      // 0 = clear, 1-3 = partly cloudy, 45-48 = fog
      // 51-67 = drizzle/rain, 71-77 = snow, 80-82 = showers
      // 95-99 = thunderstorm
      if (weatherCode >= 95) {
        return '⚡ Thunderstorm at destination! Drive safely, charging may be unsafe.';
      }
      if (weatherCode >= 80) {
        return '🌧️ Heavy showers at destination. Wet cables — be careful!';
      }
      if (weatherCode >= 71) {
        return '❄️ Snowfall at destination. Roads may be slippery, drive carefully!';
      }
      if (weatherCode >= 51 || precipitation > 0.5) {
        return '🌧️ Rain at destination. Be careful with charging cables in wet conditions.';
      }
      if (windSpeed > 50) {
        return '💨 High winds at destination (${windSpeed.toStringAsFixed(0)} km/h). Secure your vehicle.';
      }
      if (weatherCode >= 45) {
        return '🌫️ Foggy conditions at destination. Drive carefully and use headlights.';
      }
      return null; // All clear
    } catch (e) {
      debugPrint('WeatherService error: $e');
      return null; // Silently fail — weather is non-critical
    }
  }
}
