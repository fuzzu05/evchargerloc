import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://evchargerloc.onrender.com/api/auth';
  static const String _tokenKey = 'jwt_token';

  // Login (MOCKED FOR HACKATHON)
  static Future<bool> login(String email, String password) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      await saveToken('mock_jwt_token_for_hackathon');
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  // Register (MOCKED FOR HACKATHON)
  static Future<bool> register(String email, String password) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  // Save Token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Get Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Remove Token (Logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
