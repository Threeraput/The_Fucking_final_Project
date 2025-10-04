import 'package:flutter/material.dart';

class CreateAnnouncementPage extends StatefulWidget {
  final String courseTitle;

  const CreateAnnouncementPage({super.key, required this.courseTitle});

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final TextEditingController _controller = TextEditingController();

  void _createAnnouncement() {
    if (_controller.text.trim().isEmpty) return;

    Navigator.pop(context, {
      'text': _controller.text.trim(),
      'author': 'Teacher John', // ชื่อผู้ประกาศ (สามารถเปลี่ยนภายหลังให้ดึงจาก user ได้)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text('New Announcement'),
        actions: [
  Padding(
    padding: const EdgeInsets.only(right: 8.0), // เว้นขอบขวานิดหน่อยให้สวย
    child: TextButton(
      onPressed: _createAnnouncement,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white, // สีตัวอักษร
        backgroundColor: Colors.blueAccent, // สีพื้นหลังของกล่อง
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // มุมโค้งเล็กน้อย
        ),
      ),
      child: const Text(
        'Create',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    ),
  ),
],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          maxLines: 10,
          decoration: InputDecoration(
            hintText: 'Write your announcement here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
