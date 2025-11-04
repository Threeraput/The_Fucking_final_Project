// lib/services/feed_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/classwork_simple_service.dart';
import 'package:frontend/models/classwork.dart';

import '../models/feed_item.dart';
import 'attendance_service.dart';

// 🔹 helper เล็กๆ อ่านค่าความจริงจากหลายคีย์ที่ backend อาจส่งมาแตกต่างกัน
bool _truthy(Map<String, dynamic>? m, List<String> keys) {
  if (m == null) return false;
  for (final k in keys) {
    final v = m[k];
    if (v == true) return true;
    if (v is String) {
      final s = v.toLowerCase();
      if (s == 'true' || s == 'passed' || s == 'completed' || s == 'ok') {
        return true;
      }
    }
    if (v is Map && (v['passed'] == true || v['completed'] == true)) {
      return true;
    }
  }
  return false;
}

class FeedService {
  /// เดิม: สร้าง feed จาก active sessions (ยังไม่กรองตามสถานะนักเรียน)
  static Future<List<FeedItem>> getClassFeed(String classId) async {
    final items = <FeedItem>[];

    try {
      final sessions = await AttendanceService.getActiveSessions();
      for (final s in sessions) {
        if ((s['class_id']?.toString() ?? '') != classId) continue;

        final id = s['session_id']?.toString() ?? s['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        final expires = DateTime.tryParse(
          s['end_time']?.toString() ?? s['expires_at']?.toString() ?? '',
        );

        final postedAt =
            DateTime.tryParse(s['start_time']?.toString() ?? '') ??
            DateTime.now().subtract(const Duration(minutes: 1));

        items.add(
          FeedItem(
            id: id,
            classId: classId,
            type: FeedType.checkin,
            title: 'เช็คชื่อกำลังเปิดอยู่',
            postedAt: postedAt,
            expiresAt: expires,
            extra: {
              'session_id': id,
              'reverify_enabled': s['reverify_enabled'] == true,
              'radius': s['radius_meters'],
              'anchor_lat': s['anchor_lat'],
              'anchor_lon': s['anchor_lon'],
            },
          ),
        );
      }
    } catch (_) {}

    items.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return items;
  }

  /// ✅ ใหม่: เวอร์ชัน “นักเรียน” — กรองทิ้งการ์ดเช็คชื่อถ้าผู้ใช้รายนี้
  /// เช็คชื่อแล้ว **และ** reverify แล้ว
  static Future<List<FeedItem>> getClassFeedForStudent(String classId) async {
    final base = await getClassFeed(classId);
    final result = <FeedItem>[];

    for (final f in base) {
      if (f.type != FeedType.checkin) {
        result.add(f);
        continue;
      }
      final sid = f.extra['session_id']?.toString();
      if (sid == null || sid.isEmpty) {
        result.add(f);
        continue;
      }

      try {
        final status = await AttendanceService.getMyStatusForSession(sid);
        final hasCheckedIn = _truthy(status, [
          'has_checked_in',
          'checked_in',
          'present',
        ]);
        final reverifyCompleted = _truthy(status, [
          'reverify_completed',
          'has_reverified',
          'reverify_passed',
          'reverified',
          'reverify_status',
          'latest_reverify',
        ]);

        // 🔍 เงื่อนไขที่คุณต้องการ: ซ่อนเมื่อ “เช็คชื่อแล้ว” และ “reverify แล้ว”
        final hide = hasCheckedIn && reverifyCompleted;

        if (!hide) result.add(f);
      } catch (_) {
        // ถ้าดึงสถานะไม่สำเร็จ อย่าซ่อนเพื่อไม่พลาดการ์ด
        result.add(f);
      }
    }

    return result;
  }

  static Future<List<FeedItem>> getClassFeedForTeacherWithAssignments(
    String classId,
  ) async {
    final items = await getClassFeed(classId);
    try {
      final asgs =
          await ClassworkSimpleService.listAssignmentsForClassAsTeacherTyped(
            classId,
          );
      for (final a in asgs) {
        items.add(
          FeedItem(
            id: 'asg:${a.assignmentId}',
            classId: classId,
            type: FeedType.checkin, // ใช้ type เดิม แต่บอกชนิดผ่าน extra.kind
            title: 'งาน: ${a.title}',
            postedAt: a.createdAt,
            expiresAt: a.dueDate,
            extra: {
              'kind': 'assignment',
              'assignment_id': a.assignmentId,
              'title': a.title,
              'due_date': a.dueDate.toIso8601String(),
              'max_score': a.maxScore,
            },
          ),
        );
      }
    } catch (_) {}
    items.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return items;
  }

  static Future<List<FeedItem>> getClassFeedForStudentWithAssignments(
    String classId,
  ) async {
    final base = await getClassFeedForStudent(
      classId,
    ); // ฟีดที่กรองเช็คชื่อให้ก่อน
    final items = <FeedItem>[...base];
    try {
      final list = await ClassworkSimpleService.getStudentAssignmentsTyped(
        classId,
      );
      for (final v in list) {
        final a = v.assignment;
        items.add(
          FeedItem(
            id: 'asg:${a.assignmentId}',
            classId: classId,
            type: FeedType.checkin,
            title: 'งาน: ${a.title}',
            postedAt: a.createdAt,
            expiresAt: a.dueDate,
            extra: {
              'kind': 'assignment',
              'assignment_id': a.assignmentId,
              'title': a.title,
              'due_date': a.dueDate.toIso8601String(),
              'max_score': a.maxScore,
              'computed_status': latenessToString(v.computedStatus),
              'my_submission': v.mySubmission?.toJson(),
            },
          ),
        );
      }
    } catch (_) {}
    items.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return items;
  }
}


