import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../services/auth_service.dart';
import '../models/attendance_session.dart';
import '../models/attendance.dart';

/// Endpoints ที่คาดหวัง (ปรับให้ตรงกับ FastAPI ของคุณถ้าไม่เหมือน):
/// - GET  /api/v1/sessions/active
/// - POST /api/v1/sessions/open
/// - POST /api/v1/attendance/teacher-location
/// - POST /api/v1/attendance/check-in        (multipart: image + fields)
/// - POST /api/v1/attendance/re-verify       (multipart: image + fields)
/// - PATCH /api/v1/attendance/override/{id}
class AttendanceService {
  // ----------------- Sessions -----------------

  /// นักเรียน/ครู ใช้ดึง session ที่กำลังเปิดทั้งหมด
  /// คืนค่าแบบ List<Map<String, dynamic>> เพื่อให้เข้ากับ StudentCheckinScreen ปัจจุบันของคุณ
  static Future<List<Map<String, dynamic>>> getActiveSessions() async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    final url = Uri.parse('${API_BASE_URL}/sessions/active');
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      // ถ้าอยากใช้ model ในอนาคต: map เป็น AttendanceSession.fromJson(e)
      return list.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Fetch active sessions failed: ${res.body}');
    }
  }

  /// (ฝั่งครู) เปิด session เช็คชื่อ (ยังไม่ใส่ anchor ในขั้นนี้ตามโฟลว์ของคุณ)
static Future<AttendanceSession> openSession({
    required String classId,
    required int expiresInMinutes,
    required int radiusMeters,
    required double latitude, // 👈 เพิ่ม (บังคับ)
    required double longitude, // 👈 เพิ่ม (บังคับ)
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final url = Uri.parse('${API_BASE_URL}/sessions/open');

    //  ตรง schema: ต้องมี latitude/longitude
    final body = <String, dynamic>{
      'class_id': classId,
      'duration_minutes': expiresInMinutes,
      'radius_meters': radiusMeters.toDouble(),
      'latitude': latitude, 
      'longitude': longitude,
    };

    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return AttendanceSession.fromJson(jsonDecode(res.body));
    } else {
      print('❌ [openSession] Error ${res.statusCode}: ${res.body}');
      throw Exception('Open session failed [${res.statusCode}]: ${res.body}');
    }
  }


  /// (ฝั่งครู) อัปเดต anchor ของอาจารย์หลังเปิด session
  /// NOTE: endpoint นี้จะผูก anchor กับคลาส/เซสชันล่าสุดตามที่ backend คุณกำหนด
  static Future<void> updateTeacherAnchor({
    required String classId,
    required double latitude,
    required double longitude,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final user = await AuthService.getCurrentUserFromLocal();
    if (user == null) throw Exception('No current user');

    final url = Uri.parse('${API_BASE_URL}/attendance/teacher-location');
    final body = {
      'teacher_id': user.teacherId,
      'class_id': classId,
      'latitude': latitude,
      'longitude': longitude,
    };

    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Update anchor failed: ${res.body}');
    }
  }

  // ----------------- Attendance (Student) -----------------

  /// นักเรียนเช็คชื่อด้วยใบหน้า + GPS (อ่านรูปจากไฟล์ path ตามที่หน้าจอคุณส่งมา)
  /// backend จะอ่าน student จาก token (จึงไม่ต้องส่ง studentId)
  static Future<void> checkIn({
    required String sessionId,
    required String imagePath,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(
      '$API_BASE_URL/attendance/check-in',
    ); // ← ใช้ตาม backend ของคุณ
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final req = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['session_id'] = sessionId
      // ส่งสองชื่อ field เผื่อ backend ใช้ชื่อใดชื่อหนึ่ง
      ..fields['latitude'] = latitude.toString()
      ..fields['longitude'] = longitude.toString()
      ..fields['student_lat'] = latitude.toString()
      ..fields['student_lon'] = longitude.toString();

    //  เปลี่ยนชื่อพาร์ตไฟล์ให้เป็น 'file' (ตาม error)
    final mime = lookupMimeType(imagePath) ?? 'image/jpeg';
    final parts = mime.split('/');
    final filePart = await http.MultipartFile.fromPath(
      'file', // ← ต้องเป็น 'file'
      imagePath,
      contentType: MediaType(parts.first, parts.last),
    );
    req.files.add(filePart);

    final res = await req.send();
    final body = await res.stream.bytesToString();

    // debug ช่วยเวลาเจอ 4xx
    // ignore: avoid_print
    print('📤 POST $url -> ${res.statusCode}');
    // ignore: avoid_print
    print('↩️ $body');

    if (res.statusCode != 200) {
      throw Exception('Check-in failed: $body');
    }
  }

  static Future<Attendance> reVerify({
    required String sessionId,
    required String imagePath,
    required double latitude,
    required double longitude,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('รูปภาพไม่พบ: $imagePath');
    }

    final url = Uri.parse('${API_BASE_URL}/attendance/re-verify');
    final req = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['session_id'] = sessionId
      ..fields['latitude'] = latitude.toString()
      ..fields['longitude'] = longitude.toString()
      ..files.add(await http.MultipartFile.fromPath('image', imagePath));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return Attendance.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Re-verify failed: ${res.body}');
    }
  }

  // ----------------- Admin/Teacher override (optional) -----------------

  static Future<Attendance> manualOverride({
    required String attendanceId,
    required String newStatus, // "present" | "absent" | "late" | "suspected"
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final url = Uri.parse('${API_BASE_URL}/attendance/override/$attendanceId');
    final res = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': newStatus}),
    );

    if (res.statusCode == 200) {
      return Attendance.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Override failed: ${res.body}');
    }
  }

  static Future fetchActiveSessions() async {}
}
