import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_session.dart';
import '../services/auth_service.dart';

class SessionsService {
  static const String baseUrl = '$API_BASE_URL/sessions';

  /// เปิด session เช็คชื่อของอาจารย์
  static Future<AttendanceSession> openSession({
    required String classId,
    required int durationMinutes,
    required double radiusMeters,
    double? anchorLat,
    double? anchorLon,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final url = Uri.parse('$baseUrl/open');
    final body = {
      'class_id': classId,
      'duration_minutes': durationMinutes,
      'radius_meters': radiusMeters,
      if (anchorLat != null) 'anchor_lat': anchorLat,
      if (anchorLon != null) 'anchor_lon': anchorLon,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AttendanceSession.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Open session failed: ${response.body}');
    }
  }

  /// ดึงรายการ session ที่ active
  static Future<List<AttendanceSession>> fetchActiveSessions() async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final url = Uri.parse('$baseUrl/active');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => AttendanceSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Fetch sessions failed: ${response.body}');
    }
  }
}
