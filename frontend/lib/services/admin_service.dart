import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/models/users.dart';
import 'package:frontend/models/admin.dart';
import 'auth_service.dart';

class AdminService {
  static const String _baseUrl = 'http://192.168.0.200:8000/api/v1';
  static const Duration _timeout = Duration(seconds: 20);

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getAccessToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET /admin/users
  static Future<AdminUsersPage> listUsers({
    String? q,
    String? role, // admin|teacher|student
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (role != null && role.trim().isNotEmpty)
        'role': role.trim().toLowerCase(),
    };
    final url = Uri.parse(
      '$_baseUrl/admin/users',
    ).replace(queryParameters: params);
    final res = await http
        .get(url, headers: await _headers())
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('โหลดรายการผู้ใช้ไม่สำเร็จ: ${res.body}');
    }
    return AdminUsersPage.fromJson(json.decode(res.body));
  }

  // DELETE /admin/users/{user_id}
  static Future<void> deleteUser(String userId) async {
    final url = Uri.parse('$_baseUrl/admin/users/$userId');
    final res = await http
        .delete(url, headers: await _headers())
        .timeout(_timeout);
    if (res.statusCode != 204) {
      throw Exception('ลบผู้ใช้ไม่สำเร็จ: ${res.body}');
    }
  }

  // GET /admin/reports/summary
  static Future<SystemSummary> getSystemSummary({
    DateTime? start,
    DateTime? end,
  }) async {
    final params = <String, String>{
      if (start != null) 'start': start.toIso8601String(),
      if (end != null) 'end': end.toIso8601String(),
    };
    final url = Uri.parse(
      '$_baseUrl/admin/reports/summary',
    ).replace(queryParameters: params);
    final res = await http
        .get(url, headers: await _headers())
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('โหลดรายงานไม่สำเร็จ: ${res.body}');
    }
    return SystemSummary.fromJson(json.decode(res.body));
  }


    static Future<Map<String, dynamic>> listClasses({
    String? q,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
    };
    final uri = Uri.parse(
      '$_baseUrl/admin/classes',
    ).replace(queryParameters: params);
    final res = await http
        .get(uri, headers: await _headers())
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Failed to load classes: ${res.body}');
    }
    final data = json.decode(res.body);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid response for classes');
  }
}
