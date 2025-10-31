// lib/widgets/feed_cards.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/feed_item.dart';
import '../screens/student_checkin_screen.dart';
import '../screens/teacher_open_checkin_sheet.dart';

class FeedList extends StatelessWidget {
  final List<FeedItem> items;
  final bool isTeacher;
  final String classId;

  const FeedList({
    super.key,
    required this.items,
    required this.isTeacher,
    required this.classId,
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
            (e) => _FeedCard(item: e, isTeacher: isTeacher, classId: classId),
          )
          .toList(),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final FeedItem item;
  final bool isTeacher;
  final String classId;
  const _FeedCard({
    required this.item,
    required this.isTeacher,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case FeedType.checkin:
        return _CheckinCard(item: item, isTeacher: isTeacher, classId: classId);
      case FeedType.assignment:
        return _AssignmentCard(item: item);
      case FeedType.announcement:
        return _AnnouncementCard(item: item);
    }
  }
}

class _AnnouncementCard extends StatelessWidget {
  final FeedItem item;
  const _AnnouncementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy, HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderRow(
              icon: Icons.campaign,
              title: 'ประกาศใหม่',
              dateText: df.format(item.postedAt.toLocal()),
            ),
            const SizedBox(height: 8),
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            if ((item.subtitle ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('เพิ่มความคิดเห็นในชั้นเรียน'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final FeedItem item;
  const _AssignmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM, HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderRow(
              icon: Icons.assignment_outlined,
              title: 'งานใหม่',
              dateText: df.format(item.postedAt.toLocal()),
            ),
            const SizedBox(height: 8),
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            if (item.expiresAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'กำหนดส่ง: ${df.format(item.expiresAt!.toLocal())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('เปิดงาน'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckinCard extends StatelessWidget {
  final FeedItem item;
  final bool isTeacher;
  final String classId;
  const _CheckinCard({
    required this.item,
    required this.isTeacher,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    final dfTime = DateFormat('d MMM, HH:mm');
    final exp = item.expiresAt != null
        ? 'หมดอายุ: ${dfTime.format(item.expiresAt!.toLocal())}'
        : 'กำลังเปิดอยู่';
    final radius = item.extra['radius']?.toString();
    final lat = item.extra['anchor_lat']?.toString();
    final lon = item.extra['anchor_lon']?.toString();

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
            const SizedBox(height: 8),
            Row(
              children: [
                if (isTeacher)
                  FilledButton.icon(
                    onPressed: () async {
                      final ok = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) =>
                            TeacherOpenCheckinSheet(classId: classId),
                      );
                      // ครูเปิดใหม่ได้ หลังปิด sheet ค่อยรีเฟรชที่หน้าแม่
                      Navigator.of(context).maybePop(ok);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('เปิดใหม่'),
                  )
                else
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
