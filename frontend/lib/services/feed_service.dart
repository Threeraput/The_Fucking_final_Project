// lib/services/feed_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/feed_item.dart';
import 'attendance_service.dart';
import 'auth_service.dart';

class FeedService {
  /// รวบรวมฟีดของคลาส: เช็คชื่อ / งาน / ประกาศ แล้ว sort ตามเวลาโพสต์
  static Future<List<FeedItem>> getClassFeed(
    String classId, {
    bool force = false,
  }) async {
    final items = <FeedItem>[];

    try {
      // ⬅️ ส่ง force ต่อไป
      final sessions = await AttendanceService.getActiveSessions(force: force);

      String? _classIdOf(Map<String, dynamic> s) {
        final v1 = s['class_id'];
        if (v1 is String && v1.isNotEmpty) return v1;
        final v2 = s['classId'];
        if (v2 is String && v2.isNotEmpty) return v2;
        final c = s['class'] as Map<String, dynamic>?;
        if (c != null) {
          final v3 = c['class_id'] ?? c['id'];
          if (v3 is String && v3.isNotEmpty) return v3;
        }
        return null;
      }

      for (final s in sessions) {
        if ((_classIdOf(s)?.toLowerCase().trim()) !=
            classId.toLowerCase().trim())
          continue;

        final id = s['session_id']?.toString() ?? s['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        final start = DateTime.tryParse(s['start_time']?.toString() ?? '');
        final expires = DateTime.tryParse(
          s['end_time']?.toString() ?? s['expires_at']?.toString() ?? '',
        );

        final postedAt =
            start ?? DateTime.now().subtract(const Duration(minutes: 1));

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
}
