// lib/widgets/feed_cards.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/feed_item.dart';
import '../screens/student_checkin_screen.dart';
import '../screens/teacher_open_checkin_sheet.dart';

import 'package:frontend/services/sessions_service.dart';
import 'package:frontend/services/attendance_service.dart';
import 'package:frontend/utils/location_helper.dart';

class FeedList extends StatelessWidget {
  final List<FeedItem> items;
  final bool isTeacher;
  final String classId;
  final VoidCallback? onChanged; // ✅ callback ให้หน้าแม่รีเฟรช

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
    // ตอนนี้รองรับการ์ดประเภทเช็คชื่อเป็นหลัก
    // ถ้าคุณมี FeedType อื่น ๆ ค่อยเพิ่ม switch แยกภายหลังได้
    return _buildCheckinCard(context);
  }

  Widget _buildCheckinCard(BuildContext context) {
    final dfTime = DateFormat('d MMM, HH:mm');

    final exp = item.expiresAt != null
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
    final canReverify = reverifyEnabled && notExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderRow(
              icon: Icons.access_time,
              title: 'เช็คชื่อ',
              dateText: dfTime.format(item.postedAt.toLocal()),
            ),
            const SizedBox(height: 8),
            Text(
              'เช็คชื่อกำลังเปิดอยู่',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '$exp · รัศมี ${radius ?? '-'} m',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (lat != null && lon != null)
              Text(
                'Anchor: $lat, $lon',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Text(
              'Reverify: ${reverifyEnabled ? "ON" : "OFF"}',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                // ===== ปุ่มฝั่งครู =====
                if (isTeacher) ...[
                  FilledButton.icon(
                    onPressed: () async {
                      final ok = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) =>
                            TeacherOpenCheckinSheet(classId: classId),
                      );
                      // ให้หน้าแม่รีเฟรชตามผล
                      if (ok == true) onChanged?.call();
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('เปิดใหม่'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    // ถ้าอยากให้กดได้แม้ session หมดเวลา ให้เอา notExpired ออก
                    onPressed: (sessionId != null /* && notExpired */ )
                        ? () async {
                            try {
                              final next = !reverifyEnabled;
                              final enabled =
                                  await SessionsService.toggleReverify(
                                    sessionId: sessionId!,
                                    enabled: next,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      enabled
                                          ? 'เปิด reverify แล้ว'
                                          : 'ปิด reverify แล้ว',
                                    ),
                                  ),
                                );
                              }
                              onChanged?.call(); // 🔁 รีเฟรชฟีด
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'สลับ reverify ไม่สำเร็จ: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    child: Text(
                      reverifyEnabled ? 'ปิด reverify' : 'เปิด reverify',
                    ),
                  ),
                ],

                // ===== ปุ่มฝั่งนักเรียน =====
                if (!isTeacher) ...[
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              StudentCheckinScreen(classId: classId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.verified_user),
                    label: const Text('เช็คชื่อ'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: (canReverify && sessionId != null)
                        ? () async {
                            try {
                              // 1) เปิดหน้ากล้อง/เลือกรูป -> ได้ path
                              final result = await Navigator.pushNamed(
                                context,
                                '/reverify-face',
                              );
                              if (result == null ||
                                  result is! String ||
                                  result.isEmpty)
                                return;

                              // 2) ดึง GPS
                              final pos =
                                  await LocationHelper.getCurrentPositionOrThrow();

                              // 3) ยิง API re-verify
                              await AttendanceService.reVerify(
                                sessionId: sessionId!,
                                imagePath: result,
                                latitude: pos.latitude,
                                longitude: pos.longitude,
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('ยืนยันตัวตนซ้ำสำเร็จ'),
                                  ),
                                );
                              }
                              onChanged?.call(); // 🔁 รีเฟรชฟีด
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                                );
                              }
                            }
                          }
                        : null,
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('ยืนยันซ้ำ'),
                  ),
                ],

                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('เพิ่มความคิดเห็น'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, size: 18, color: color),
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
