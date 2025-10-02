import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  // ตัวอย่าง Notification List
  final List<Map<String, String>> _notifications = const [
    {'title': 'Assignment Due', 'desc': 'Math homework due tomorrow'},
    {'title': 'New Announcement', 'desc': 'Science class starts at 10 AM'},
    {'title': 'Grade Posted', 'desc': 'Your English assignment has been graded'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.separated(
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          return ListTile(
            leading: const Icon(Icons.notifications, color: Colors.orange),
            title: Text(notif['title']!),
            subtitle: Text(notif['desc']!),
            onTap: () {
              // กดแต่ละ Notification สามารถไปหน้ารายละเอียดได้
              // Navigator.push(...);
            },
          );
        },
      ),
    );
  }
}
