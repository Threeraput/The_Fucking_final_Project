// lib/services/feed_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:frontend/services/classwork_simple_service.dart';
import 'package:frontend/models/classwork.dart';
import '../models/feed_item.dart';
import 'attendance_service.dart';

// ✅ เพิ่มบริการประกาศ
import 'package:frontend/services/announcement_service.dart';

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
  /// ✅ ดึงฟีดพื้นฐาน (เช็คชื่อ) + ✅ รวม "ประกาศ" + ✅ ต่อท้าย "งาน (ครู)"
  static Future<List<FeedItem>> getClassFeed(String classId) async {
    final items = <FeedItem>[];

    // 1) เช็คชื่อ (เดิม)
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

    // 2) ✅ ประกาศ (announcements) — ใช้ extra.kind = 'announcement' (ไม่เพิ่ม enum ใหม่)
    try {
      final anns = await AnnouncementService.listByClassId(classId);
      for (final a in anns) {
        items.add(
          FeedItem(
            id: 'ann:${a['announcement_id']}',
            classId: classId,
            type: FeedType.announcement, //  ชนิดเป็น announcement
            title: (a['title']?.isEmpty ?? true) ? 'ประกาศ' : a['title'],
            postedAt:
                DateTime.tryParse(a['created_at']?.toString() ?? '') ??
                DateTime.now(),
            expiresAt: a['expires_at'],
            extra: {
              'kind': 'announcement', //  ชัดเจนว่าคือประกาศ
              'body': a['body'],
              'pinned': a['pinned'],
              'visible': a['visible'],
              'author_name': a['author_name'],
            },
          ),
        );
      }
    } catch (e) {
      print('⚠️ โหลดประกาศไม่สำเร็จ: $e');
    }

    // 3) ✅ งาน (สำหรับครู) — ของเดิม
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

    // ✅ เรียงลำดับ: pinned (เฉพาะประกาศ) มาก่อน แล้วค่อยเวลาล่าสุด
    items.sort((a, b) {
      final aKind = a.extra['kind']?.toString();
      final bKind = b.extra['kind']?.toString();

      final aIsCheckin = a.type == FeedType.checkin || aKind == 'checkin';
      final bIsCheckin = b.type == FeedType.checkin || bKind == 'checkin';

      // 🥇 ถ้าอันใดอันหนึ่งเป็น "เช็คชื่อ" → ให้เรียงขึ้นก่อน
      if (aIsCheckin != bIsCheckin) {
        return aIsCheckin ? -1 : 1; // a ขึ้นก่อนถ้าเป็น checkin
      }

      // 🥈 ถ้าเป็นประกาศทั้งคู่ → ให้ pinned ขึ้นก่อน
      final aIsAnn = aKind == 'announcement';
      final bIsAnn = bKind == 'announcement';
      if (aIsAnn && bIsAnn) {
        final ap = a.extra['pinned'] == true;
        final bp = b.extra['pinned'] == true;
        if (ap != bp) return bp ? 1 : -1; // pinned (true) มาก่อน
      }

      // 🥉 ที่เหลือเรียงเวลาใหม่ → เก่า
      return b.postedAt.compareTo(a.postedAt);
    });

    return items;
  }

  /// ✅ ฟีดสำหรับนักเรียน (เช็คชื่อ + งานนักเรียน + ประกาศ)
  static Future<List<FeedItem>> getClassFeedForStudentWithAssignments(
    String classId,
  ) async {
    final result = <FeedItem>[];

    // 1) เอาฟีดฐาน (เช็คชื่อ + ประกาศ + งานครูที่ดึงมาแล้ว แต่เราจะกรองการ์ดเช็คชื่อ)
    final checkins = await getClassFeed(classId);
    for (final f in checkins) {
      // 1) เอาฟีดฐาน (เช็คชื่อ + ประกาศ + งานครูที่ดึงมาแล้ว แต่เราจะกรองการ์ดเช็คชื่อ)
      final base = await getClassFeed(classId);
      for (final f in base) {
        // ถ้าเป็นประกาศ/งาน → ใส่ได้เลย (นักเรียนก็เห็นได้)
        final kind = f.extra['kind']?.toString();
        if (kind == 'announcement' || kind == 'assignment') {
          result.add(f);
          continue;
        }
      }

      // เฉพาะการ์ดเช็คชื่อ → กรองตามสถานะ
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

    // 2) เพิ่ม “งานของนักเรียน” (สถานะของฉัน)
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

    // ✅ เรียงลำดับด้วยกฎเดียวกับด้านบน
    result.sort((a, b) {
      final now = DateTime.now();
      final aKind = a.extra['kind']?.toString();
      final bKind = b.extra['kind']?.toString();

      final aIsCheckin = a.type == FeedType.checkin || aKind == 'checkin';
      final bIsCheckin = b.type == FeedType.checkin || bKind == 'checkin';

      // เช็คชื่อที่ยังไม่หมดอายุอยู่บนสุด
      if (aIsCheckin || bIsCheckin) {
        final aExpired = a.expiresAt != null && a.expiresAt!.isBefore(now);
        final bExpired = b.expiresAt != null && b.expiresAt!.isBefore(now);

        if (aExpired != bExpired)
          return aExpired ? 1 : -1; // ยังเปิดอยู่ขึ้นก่อน
        if (aIsCheckin != bIsCheckin)
          return aIsCheckin ? -1 : 1; // เช็คชื่อมาก่อน
      }

      // ประกาศที่ปักหมุดอยู่ถัดมา
      final aIsAnn = aKind == 'announcement';
      final bIsAnn = bKind == 'announcement';
      if (aIsAnn && bIsAnn) {
        final ap = a.extra['pinned'] == true;
        final bp = b.extra['pinned'] == true;
        if (ap != bp) return bp ? 1 : -1; // pinned มาก่อน
      }

      // ที่เหลือเรียงตามเวลาใหม่สุด
      return b.postedAt.compareTo(a.postedAt);
    });

    return result;
  }

  /// ✅ ฟีดของครู (เช็คชื่อ + งานครู + ประกาศ)
  static Future<List<FeedItem>> getClassFeedForTeacherWithAssignments(
    String classId,
  ) async {
    final items = await getClassFeed(classId);
    // ใช้กฎเรียงเดียวกัน (กันพลาดถ้ามีการเรียกฟังก์ชันนี้ตรง ๆ)
    items.sort((a, b) {
      final aIsAnn = (a.extra['kind']?.toString() == 'announcement');
      final bIsAnn = (b.extra['kind']?.toString() == 'announcement');
      if (aIsAnn && bIsAnn) {
        final ap = a.extra['pinned'] == true;
        final bp = b.extra['pinned'] == true;
        if (ap != bp) return bp ? 1 : -1;
      }
      return b.postedAt.compareTo(a.postedAt);
    });
    return items;
  }
}
