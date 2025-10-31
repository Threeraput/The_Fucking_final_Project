// lib/services/feed_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/feed_item.dart';
import 'attendance_service.dart';
import 'auth_service.dart';

class FeedService {
  /// รวบรวมฟีดของคลาส: เช็คชื่อ / งาน / ประกาศ แล้ว sort ตามเวลาโพสต์
  static Future<List<FeedItem>> getClassFeed(String classId) async {
    final items = <FeedItem>[];

    // 1) ดึง Session เช็คชื่อที่กำลังเปิด (จาก AttendanceService)
    try {
      final sessions = await AttendanceService.getActiveSessions();
      for (final s in sessions) {
        if ((s['class_id']?.toString() ?? '') != classId) continue;

        // fields ที่ฝั่งคุณส่งมา: session_id, expires_at, radius_meters, anchor_lat, anchor_lon
        final id = s['session_id']?.toString() ?? '';
        final expires = DateTime.tryParse(
          s['end_time']?.toString() ?? s['expires_at']?.toString() ?? '',
        );
        // ในที่นี้ให้ postedAt = now - 1min (เพราะ backend ไม่ส่ง start_time ก็ได้)
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
              'radius': s['radius_meters'],
              'anchor_lat': s['anchor_lat'],
              'anchor_lon': s['anchor_lon'],
            },
          ),
        );
      }
    } catch (_) {}

    // 2) TODO: ดึง "ประกาศ" ของคลาส (ตัวอย่าง wire จุดเดียวไว้)
    // final anns = await AnnouncementService.listByClass(classId);
    // items.addAll(anns.map((a) => FeedItem(... type: FeedType.announcement ...)));

    // 3) TODO: ดึง "งาน" ของคลาส
    // final works = await AssignmentService.listByClass(classId);

    // เรียงตามเวลาโพสต์ จากใหม่ไปเก่า
    items.sort((a, b) => (b.postedAt).compareTo(a.postedAt));
    return items;
  }
}
