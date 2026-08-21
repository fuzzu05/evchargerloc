import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/models/station.dart';

class StationService {
  static const String baseUrl =
      'https://evchargerloc.onrender.com/api/stations';

  // Get all stations
  static Future<List<ChargingStation>> getStations() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChargingStation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load stations');
      }
    } catch (e) {
      throw Exception('Error fetching stations: $e');
    }
  }

  // Get nearby stations using sync endpoint (assuming backend OpenChargeMapSync)
  static Future<List<ChargingStation>> getNearbyStations(
    double lat,
    double lng, {
    double distance = 10.0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync?lat=$lat&lng=$lng&distance=$distance'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChargingStation.fromJson(json)).toList();
      } else {
        // Fallback to getting all stations if sync fails
        return await getStations();
      }
    } catch (e) {
      return await getStations();
    }
  }
}
