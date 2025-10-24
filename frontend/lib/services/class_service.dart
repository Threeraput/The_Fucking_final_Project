// File: lib/services/class_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/classroom.dart';
import 'auth_service.dart' show AuthService; // ใช้เฉพาะ getAccessToken()

//  ตั้ง BASE_URL ไว้ในไฟล์นี้ ไม่ต้อง import จาก auth_service.dart
const String API_BASE_URL = 'http://192.168.0.200:8000/api/v1';
class ClassService {
  // ===== Headers + Error Handler =====
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getAccessToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Exception _errorFrom(http.Response res) {
    try {
      final m = json.decode(res.body);
      final msg = m['detail'] ?? m['message'] ?? res.body;
      return Exception(msg.toString());
    } catch (_) {
      return Exception(res.body);
    }
  }

  // ===== API Calls =====

  /// 1) POST /classes/ (สร้างห้องเรียน)
  static Future<Classroom> createClassroom(ClassroomCreate data) async {
    final url = Uri.parse('$API_BASE_URL/classes/');
    final res = await http.post(
      url,
      headers: await _headers(),
      body: json.encode(data.toJson()),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return Classroom.fromJson(json.decode(res.body));
    }
    throw _errorFrom(res);
  }

  /// 2) GET /classes/taught (ห้องเรียนที่สอน)
  static Future<List<Classroom>> getTaughtClasses() async {
    final url = Uri.parse('$API_BASE_URL/classes/taught');
    final res = await http.get(url, headers: await _headers());
    if (res.statusCode == 200) {
      final list = (json.decode(res.body) as List).cast<dynamic>();
      return list
          .map((e) => Classroom.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _errorFrom(res);
  }

  /// 3) POST /classes/join (นักเรียนเข้าร่วมด้วย code)
  static Future<void> joinClassroom(String code) async {
    final token = await AuthService.getAccessToken();
    final url = Uri.parse('$API_BASE_URL/classes/join');

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'code': code}),
    );

    if (res.statusCode == 200) {
      return; // สำเร็จ ไม่ต้องทำอะไรเพิ่ม
    }

    // ถ้าเกิด error จาก backend
    String message = 'เข้าร่วมคลาสไม่สำเร็จ';
    try {
      final data = json.decode(res.body);
      if (data['detail'] != null) {
        message = data['detail'];
      }
    } catch (_) {}

    throw Exception(message);
  }

  /// 4) DELETE /classes/{class_id}/students/{student_id}
  static Future<void> removeStudent(String classId, String studentId) async {
    final url = Uri.parse('$API_BASE_URL/classes/$classId/students/$studentId');
    final res = await http.delete(url, headers: await _headers());
    if (res.statusCode == 204) return;
    throw _errorFrom(res);
  }

  /// 5) PATCH /classes/{class_id} (อัปเดตรายละเอียดห้อง)
  static Future<Classroom> updateClassroom(
    String classId,
    ClassroomUpdate data,
  ) async {
    final url = Uri.parse('$API_BASE_URL/classes/$classId');
    final res = await http.patch(
      url,
      headers: await _headers(),
      body: json.encode(data.toJson()),
    );
    if (res.statusCode == 200) {
      return Classroom.fromJson(json.decode(res.body));
    }
    throw _errorFrom(res);
  }

  /// 6) DELETE /classes/{class_id} (ลบห้อง)
  static Future<void> deleteClassroom(String classId) async {
    final url = Uri.parse('$API_BASE_URL/classes/$classId');
    final res = await http.delete(url, headers: await _headers());
    if (res.statusCode == 204) return;
    throw _errorFrom(res);
  }

  /// 7) GET /classes/{class_id} (รายละเอียดห้อง)
  static Future<Classroom> getClassroomDetails(String classId) async {
    final url = Uri.parse('$API_BASE_URL/classes/$classId');
    final res = await http.get(url, headers: await _headers());
    if (res.statusCode == 200) {
      return Classroom.fromJson(json.decode(res.body));
    }
    throw _errorFrom(res);
  }
/// NEW: GET /classes/enrolled - รายการคลาสที่นักเรียนเข้าร่วม
  static Future<List<Classroom>> getJoinedClasses() async {
    final url = Uri.parse('$API_BASE_URL/classes/enrolled');
    final res = await http.get(url, headers: await _headers());
    if (res.statusCode == 200) {
      final list = (json.decode(res.body) as List).cast<dynamic>();
      return list
          .map((e) => Classroom.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _errorFrom(res);
  }
}


