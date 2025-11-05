// lib/widgets/feed_cards.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/feed_item.dart';
import '../screens/student_checkin_screen.dart';
import 'package:frontend/services/sessions_service.dart';
import 'package:frontend/services/attendance_service.dart';
import 'package:frontend/utils/location_helper.dart';

// ✅ เพิ่ม import สำหรับการ์ดงาน (assignment)
import 'package:frontend/widgets/assignment_card.dart';

class FeedList extends StatelessWidget {
  final List<FeedItem> items;
  final bool isTeacher;
  final String classId;
  final VoidCallback? onChanged; // callback ให้หน้าแม่รีเฟรช

  const FeedList({
    super.key,
    required this.items,
    required this.isTeacher,
    required this.classId,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(top: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No announcements yet.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: items
          .map(
            (e) => _FeedCard(
              item: e,
              isTeacher: isTeacher,
              classId: classId,
              onChanged: onChanged,
            ),
          )
          .toList(),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final FeedItem item;
  final bool isTeacher;
  final String classId;
  final VoidCallback? onChanged;

  const _FeedCard({
    required this.item,
    required this.isTeacher,
    required this.classId,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ แยกชนิดการ์ดตาม extra.kind
    final kind = (item.extra['kind'] ?? '').toString();

    if (kind == 'assignment') {
      return AssignmentCard(
        classId: classId,
        extra: item.extra,
        postedAt: item.postedAt,
        isTeacher: isTeacher,
        onChanged: onChanged,
      );
    }

    // ✅ ค่าเริ่มต้น: การ์ดเช็คชื่อ (เดิม)
    return _buildCheckinCard(context);
  }

  /// ===== การ์ดเช็คชื่อ (เดิม) =====
  Widget _buildCheckinCard(BuildContext context) {
    final dfTime = DateFormat('d MMM, HH:mm');
    final expText = item.expiresAt != null
        ? 'หมดอายุ: ${dfTime.format(item.expiresAt!.toLocal())}'
        : 'กำลังเปิดอยู่';

    final radius = item.extra['radius']?.toString();
    final lat = item.extra['anchor_lat']?.toString();
    final lon = item.extra['anchor_lon']?.toString();

    // ข้อมูลสำหรับ reverify
    final sessionId = item.extra['session_id']?.toString();
    final reverifyEnabled = item.extra['reverify_enabled'] == true;

    final nowUtc = DateTime.now().toUtc();
    final notExpired = (item.expiresAt != null)
        ? item.expiresAt!.toUtc().isAfter(nowUtc)
        : false;

    // ถ้าไม่มี sessionId → การ์ดแบบพื้นฐาน
    if (sessionId == null || sessionId.isEmpty) {
      return _baseCard(
        context: context,
        title: 'เช็คชื่อ',
        expText: expText,
        radius: radius,
        lat: lat,
        lon: lon,
        reverifyEnabled: reverifyEnabled,
        trailing: _studentOrTeacherButtons(
          context: context,
          sessionId: null,
          hasCheckedIn: false,
          canReverify: false,
        ),
      );
    }

    // ถ้ามี sessionId → โหลดสถานะของผู้ใช้
    return FutureBuilder<Map<String, dynamic>>(
      future: AttendanceService.getMyStatusForSession(sessionId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        Map<String, dynamic> status = {};
        if (snap.hasData && snap.data is Map<String, dynamic>) {
          status = snap.data!;
        }

        final hasCheckedIn = status['has_checked_in'] == true;
        final canReverifyFlag = status['can_reverify'] == true;
        final canReverify = canReverifyFlag || (reverifyEnabled && notExpired);

        return _baseCard(
          context: context,
          title: 'เช็คชื่อ',
          expText: expText,
          radius: radius,
          lat: lat,
          lon: lon,
          reverifyEnabled: reverifyEnabled,
          trailing: _studentOrTeacherButtons(
            context: context,
            sessionId: sessionId,
            hasCheckedIn: hasCheckedIn,
            canReverify: canReverify,
          ),
        );
      },
    );
  }

  /// ============ การ์ดพื้นฐาน ============
  Widget _baseCard({
    required BuildContext context,
    required String title,
    required String expText,
    required String? radius,
    required String? lat,
    required String? lon,
    required bool reverifyEnabled,
    required Widget trailing,
  }) {
    final dfTime = DateFormat('d MMM, HH:mm');

    return Card(
  margin: const EdgeInsets.only(bottom: 12),
  child: Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderRow(
          icon: Icons.access_time,
          title: title,
          dateText: dfTime.format(item.postedAt.toLocal()),
        ),
        const SizedBox(height: 8),

        // RichText สำหรับ expText และ radius
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14),
            children: [
              TextSpan(text: '$expText · '),
              const TextSpan(
                text: 'รัศมี ',
                style: TextStyle(fontSize: 15),
              ),
              TextSpan(
                text: '${radius ?? '-'} m',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 3),

        // แสดง Anchor
        if (lat != null && lon != null)
          Text(
            'Anchor: $lat, $lon',
            style: Theme.of(context).textTheme.bodySmall,
          ),

        const SizedBox(height: 3),

        // แสดง Reverify (ON/OFF)
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodySmall,
            children: [
              const TextSpan(text: 'Reverify: '),
              TextSpan(
                text: reverifyEnabled ? 'ON' : 'OFF',
                style: TextStyle(
                  color: reverifyEnabled ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Row(children: [trailing]),
      ],
    ),
  ),
);
  }

  /// ปุ่มฝั่งครู/นักเรียน (เฉพาะการ์ดเช็คชื่อ)
  Widget _studentOrTeacherButtons({
    required BuildContext context,
    required String? sessionId,
    required bool hasCheckedIn,
    required bool canReverify,
  }) {
   if (isTeacher) {
  // ปุ่มสำหรับครู: toggle reverify
  final isEnabled = item.extra['reverify_enabled'] == true;

  return OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white, // สีข้อความบนปุ่ม
      backgroundColor: isEnabled ? Colors.red : Colors.green, // 🔁 สลับสี
      side: BorderSide(color: isEnabled ? Colors.red : Colors.green), // เส้นขอบ
    ),
    onPressed: (sessionId != null)
        ? () async {
            try {
              final next = !isEnabled;
              final enabled = await SessionsService.toggleReverify(
                sessionId: sessionId!,
                enabled: next,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      enabled ? 'เปิด reverify แล้ว' : 'ปิด reverify แล้ว',
                      style: const TextStyle(color: Colors.black),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              onChanged?.call();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('สลับ reverify ไม่สำเร็จ: $e'),
                  ),
                );
              }
            }
          }
        : null,
    child: Text(isEnabled ? 'ปิด reverify' : 'เปิด reverify'),
  );
}


    // นักเรียน
    if (sessionId == null) return const SizedBox.shrink();
    final buttons = <Widget>[];

    // ปุ่มเช็คชื่อ
    if (!hasCheckedIn) {
      buttons.add(
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.blue
          ),
          onPressed: () async {
            final ok = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentCheckinScreen(classId: classId),
              ),
            );
            if (ok == true) onChanged?.call();
          },
          icon: const Icon(Icons.verified_user),
          label: const Text('เช็คชื่อ'),
        ),
      );
      buttons.add(const SizedBox(width: 12));
    }

    // ปุ่มยืนยันซ้ำ
    buttons.add(
      FutureBuilder<bool>(
        future: AttendanceService.getIsReverified(sessionId),
        builder: (context, snap) {
          final isReverified = snap.data == true;
          final enableReverify = hasCheckedIn && canReverify && !isReverified;

          return OutlinedButton.icon(
            onPressed: enableReverify
                ? () async {
                    try {
                      final result = await Navigator.pushNamed(
                        context,
                        '/reverify-face',
                      );
                      if (result == null || result is! String || result.isEmpty)
                        return;

                      final pos =
                          await LocationHelper.getCurrentPositionOrThrow();
                      await AttendanceService.reVerify(
                        sessionId: sessionId,
                        imagePath: result,
                        latitude: pos.latitude,
                        longitude: pos.longitude,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ยืนยันตัวตนซ้ำสำเร็จ')),
                        );
                      }
                      onChanged?.call();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                        );
                      }
                    }
                  }
                : null,
            label: Text(
              style: TextStyle(
                color: Colors.black
              ),
              isReverified ? 'ยืนยันแล้ว' : 'ยืนยันซ้ำ'),
          );
        },
      ),
    );

    return Row(children: buttons);
  }
}

class _HeaderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String dateText;

  const _HeaderRow({
    required this.icon,
    required this.title,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.inverseSurface;
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.blue,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        Text(dateText, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}