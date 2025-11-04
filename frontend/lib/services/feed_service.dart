// lib/services/feed_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/classwork_simple_service.dart';
import 'package:frontend/models/classwork.dart';
import '../models/feed_item.dart';
import 'attendance_service.dart';

/// Helper เล็กๆ: แปลงค่าจาก backend เป็น boolean
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
  /// ✅ ดึงฟีดพื้นฐาน (เช็คชื่อ)
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
    } catch (e) {
      print('⚠️ โหลด session feed ไม่สำเร็จ: $e');
    }

    // ✅ ต่อท้ายด้วย assignments (สำหรับครู)
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
            type: FeedType.assignment,
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
    } catch (e) {
      print('⚠️ โหลด assignments (ครู) ไม่สำเร็จ: $e');
    }

    // ✅ เรียงจากใหม่ไปเก่า
    items.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return items;
  }

  /// ✅ ฟีดสำหรับนักเรียน (เช็คชื่อ + งาน)
  static Future<List<FeedItem>> getClassFeedForStudentWithAssignments(
    String classId,
  ) async {
    final result = <FeedItem>[];

    // 1. เอาฟีดเช็คชื่อที่ยังไม่ยืนยันครบ
    final checkins = await getClassFeed(classId);
    for (final f in checkins) {
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
        ]);

        // 🔍 ซ่อนถ้าเช็คชื่อ + reverify แล้ว
        if (!(hasCheckedIn && reverifyCompleted)) {
          result.add(f);
        }
      } catch (_) {
        result.add(f); // fallback ถ้าเรียกไม่สำเร็จ
      }
    }

    // 2. เพิ่มงานของนักเรียน
    try {
      final list = await ClassworkSimpleService.getStudentAssignmentsTyped(
        classId,
      );
      for (final v in list) {
        final a = v.assignment;
        result.add(
          FeedItem(
            id: 'asg:${a.assignmentId}',
            classId: classId,
            type: FeedType.assignment,
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
    } catch (e) {
      print('⚠️ โหลด assignments (นักเรียน) ไม่สำเร็จ: $e');
    }

    result.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return result;
  }

  /// ✅ ฟีดของครู (เช็คชื่อ + งาน)
  static Future<List<FeedItem>> getClassFeedForTeacherWithAssignments(
    String classId,
  ) async {
    final items = await getClassFeed(classId);

    // (มี assignments แล้วใน getClassFeed อยู่แล้ว)
    items.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return items;
  }
}
