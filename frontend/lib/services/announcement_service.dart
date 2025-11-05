import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart' show AuthService;

const String API_BASE_URL = 'http://192.168.0.200:8000/api/v1';

class AnnouncementDto {
  final String announcementId;
  final String classId;
  final String teacherId;
  final String title;
  final String? body;
  final bool pinned;
  final bool visible;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;

  AnnouncementDto({
    required this.announcementId,
    required this.classId,
    required this.teacherId,
    required this.title,
    this.body,
    required this.pinned,
    required this.visible,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
  });

  factory AnnouncementDto.fromJson(Map<String, dynamic> j) {
    DateTime? _p(String? s) =>
        s == null ? null : DateTime.tryParse(s)?.toLocal();
    return AnnouncementDto(
      announcementId:
          j['announcement_id']?.toString() ?? j['id']?.toString() ?? '',
      classId: j['class_id']?.toString() ?? '',
      teacherId: j['teacher_id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      body: j['body']?.toString(),
      pinned: j['pinned'] == true,
      visible: j['visible'] == true,
      createdAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(j['updated_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      expiresAt: _p(j['expires_at']?.toString()),
    );
  }
}

class AnnouncementService {
  /// ✅ แนบ token ทุกครั้ง
  static Future<Map<String, String>> _authHeaders() async {
    final t = await AuthService.getAccessToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  /// ✅ สร้างประกาศและคืน DTO กลับมา
  static Future<AnnouncementDto> createDto({
    required String classId,
    required String title,
    String? body,
    bool pinned = false,
    bool visible = true,
    DateTime? expiresAt,
  }) async {
    final url = Uri.parse('$API_BASE_URL/announcements');
    final payload = {
      'class_id': classId,
      'title': title,
      'body': body,
      'pinned': pinned,
      'visible': visible,
      'expires_at': expiresAt?.toUtc().toIso8601String(),
    };

    final res = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('สร้างประกาศไม่สำเร็จ: ${res.body}');
    }
    return AnnouncementDto.fromJson(jsonDecode(res.body));
  }

  /// ✅ ดึงรายการประกาศของคลาส
  static Future<List<AnnouncementDto>> listForClass(String classId) async {
    final url = Uri.parse('$API_BASE_URL/announcements/class/$classId');
    final res = await http.get(url, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('โหลดประกาศไม่สำเร็จ: ${res.body}');
    }
    final List arr = jsonDecode(res.body) as List;
    return arr.map((e) => AnnouncementDto.fromJson(e)).toList();
  }

  /// ✅ ใช้สำหรับ feed service (คืนค่า Map)
  static Future<List<Map<String, dynamic>>> listByClassId(
    String classId,
  ) async {
    final url = Uri.parse('$API_BASE_URL/announcements/class/$classId');
    final res = await http.get(url, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('โหลดประกาศไม่สำเร็จ (${res.statusCode})');
    }

    final data = jsonDecode(res.body);
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      return [];
    }
  }

  /// ✅ สำหรับ CreateAnnouncementScreen (ไม่ต้องการ object)
  static Future<bool> create({
    required String classId,
    required String title,
    String? body,
    bool pinned = false,
    bool visible = true,
    DateTime? expiresAt,
  }) async {
    final url = Uri.parse('$API_BASE_URL/announcements');
    final payload = {
      'class_id': classId,
      'title': title,
      if (body != null && body.isNotEmpty) 'body': body,
      'pinned': pinned,
      'visible': visible,
      if (expiresAt != null) 'expires_at': expiresAt.toUtc().toIso8601String(),
    };

    final res = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('สร้างประกาศไม่สำเร็จ: ${res.body}');
    }

    return true;
  }

  /// ✏️ อัปเดตประกาศ (PATCH /announcements/{id})
  static Future<AnnouncementDto> update({
    required String announcementId,
    String? title,
    String? body,
    bool? pinned,
    bool? visible,
    DateTime? expiresAt,
  }) async {
    final url = Uri.parse('$API_BASE_URL/announcements/$announcementId');
    final payload = {
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (pinned != null) 'pinned': pinned,
      if (visible != null) 'visible': visible,
      if (expiresAt != null) 'expires_at': expiresAt.toUtc().toIso8601String(),
    };

    final res = await http.patch(
      url,
      headers: await _authHeaders(),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      throw Exception('อัปเดตประกาศไม่สำเร็จ: ${res.body}');
    }

    return AnnouncementDto.fromJson(jsonDecode(res.body));
  }

  /// 🗑️ ลบประกาศ (DELETE /announcements/{id})
  static Future<void> delete(String announcementId) async {
    final url = Uri.parse('$API_BASE_URL/announcements/$announcementId');
    final res = await http.delete(url, headers: await _authHeaders());

    if (res.statusCode != 204) {
      throw Exception('ลบประกาศไม่สำเร็จ: ${res.body}');
    }
  }
}
