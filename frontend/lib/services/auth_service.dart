import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/users.dart';
import '../models/token.dart';

// ตรวจสอบ BASE_URL ของคุณให้ตรงกับ Backend
const String API_BASE_URL = 'http://192.168.1.154:5000/api/v1';

class AuthService {
  static Future<Token?> login(String username, String password) async {
    final url = Uri.parse('$API_BASE_URL/auth/auth/token');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'password',
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final token = Token.fromJson(json.decode(response.body));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', token.accessToken);
        await prefs.setString('currentUser', json.encode(token.user.toJson()));
        return token;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to login');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  static Future<User> register(Map<String, dynamic> userData) async {
    final url = Uri.parse('$API_BASE_URL/auth/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 201) {
        return User.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to register');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  static Future<User?> getCurrentUserFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('currentUser');
    if (userJson != null) {
      return User.fromJson(json.decode(userJson));
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('currentUser');
  }
}
