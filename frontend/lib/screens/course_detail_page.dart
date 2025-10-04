import 'package:flutter/material.dart';
import 'package:frontend/screens/announcement.dart';
import 'package:intl/intl.dart'; // ใช้สำหรับจัดรูปแบบวันที่
import 'package:frontend/screens/create_announcement_page.dart';

class CourseDetailPage extends StatefulWidget {
  final Map<String, String> course;

  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  List<Map<String, String>> announcements = [];

  void _addAnnouncement(Map<String, String> announcement) {
    setState(() {
      // เพิ่มเวลาประกาศอัตโนมัติ
      final now = DateTime.now();
      final formattedDate = DateFormat('d MMM yyyy, HH:mm').format(now);
      announcement['datetime'] = formattedDate;
      announcements.insert(0, announcement);
    });
  }

  void _editAnnouncement(int index) async {
    final old = announcements[index];
    final TextEditingController controller = TextEditingController(
      text: old['text'] ?? '',
    );
    String? newText = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Announcement'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Edit your announcement...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newText != null && newText.isNotEmpty) {
      setState(() {
        announcements[index]['text'] = newText;
      });
    }
  }

  void _deleteAnnouncement(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text(
          'Are you sure you want to delete this announcement?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                announcements.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;

    return Scaffold(
      appBar: AppBar(title: Text(course['title'] ?? 'Course Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 รายละเอียดวิชา
              SizedBox(
                width: double.infinity,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Description: ${course['desc'] ?? ''}'),
                        const SizedBox(height: 8),
                        Text('Location: ${course['location'] ?? ''}'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 ปุ่มสร้างประกาศ
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateAnnouncementPage(
                        courseTitle: course['title'] ?? '',
                      ),
                    ),
                  );
                  if (result != null && result is Map<String, String>) {
                    _addAnnouncement(result);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create Announcement',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 รายการประกาศ
              const Text(
                'Announcements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (announcements.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No announcements yet.'),
                  ),
                )
              else
                Column(
                  children: announcements.asMap().entries.map((entry) {
                    final i = entry.key;
                    final a = entry.value;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          16,
                        ), // ให้ตรงกับ Card
                        onTap: () {
                          // เปิดหน้า AnnouncementDetailPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AnnouncementDetailPage(announcement: a),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16), // ใส่ Padding รอบๆ
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 แถวโปรไฟล์ + ชื่อ + วันเวลา + ปุ่ม
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(
                                    backgroundImage: AssetImage(
                                      'assets/profile.jpg',
                                    ),
                                    radius: 28, // ขนาดใหญ่ขึ้นนิดหน่อย
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a['author'] ?? 'Unknown Author',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          a['datetime'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_horiz,
                                      color: Colors.grey,
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editAnnouncement(i);
                                      } else if (value == 'delete') {
                                        _deleteAnnouncement(i);
                                      }
                                    },
                                    color: Colors.white,
                                    itemBuilder: (BuildContext context) => [
                                      const PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Text(
                                          'Edit',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 12,
                              ), // ระยะห่างระหว่าง header กับข้อความ
                              // 🔹 ข้อความประกาศ
                              Text(
                                a['text'] ?? '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
