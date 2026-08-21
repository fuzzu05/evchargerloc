import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/models/booking.dart';

class BookingService {
  static const String baseUrl =
      'https://evchargerloc.onrender.com/api/bookings';

  // Get User Bookings
  static Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/$userId'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }

  // Create Booking
  static Future<Booking> createBooking(Booking booking) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(booking.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Booking.fromJson(data);
      } else {
        throw Exception('Failed to create booking');
      }
    } catch (e) {
      throw Exception('Error creating booking: $e');
    }
  }
}
