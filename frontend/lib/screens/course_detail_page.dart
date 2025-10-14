import 'package:flutter/material.dart';
import 'package:frontend/screens/announcement.dart';
import 'package:intl/intl.dart';
import 'package:frontend/screens/create_announcement_page.dart';
import 'package:frontend/screens/classwork_page.dart';
import 'package:frontend/screens/people_page.dart';
import 'package:frontend/screens/report_page.dart';

class CourseDetailPage extends StatefulWidget {
  final Map<String, String> course;

  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  int _selectedIndex = 0; // 👉 เก็บสถานะว่าอยู่แท็บไหน
  List<Map<String, String>> assignments = []; // เก็บ Assignment สำหรับ Classwork
  List<Map<String, String>> announcements = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

   void _addAssignment(Map<String, String> assignment) {
    setState(() {
      assignments.insert(0, assignment);
      
      // เพิ่มเข้า Stream ด้วย
      _addAnnouncement({
        'author': assignment['author'] ?? 'Instructor',
        'text': '${assignment['title']}\n${assignment['description']}',
        'datetime': DateFormat('d MMM yyyy, HH:mm').format(DateTime.now()),
        
      });
    });
  }

  void _addAnnouncement(Map<String, String> announcement) {
    setState(() {
      final now = DateTime.now();
      final formattedDate = DateFormat('d MMM yyyy, HH:mm').format(now);
      announcement['datetime'] = formattedDate;
      announcements.insert(0, announcement);
    });
  }

  void _editAnnouncement(int index) async {
    final old = announcements[index];
    final controller = TextEditingController(text: old['text'] ?? '');
    String? newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
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

  // 🔹 หน้าต่าง ๆ ที่อยู่ในแต่ละแท็บ
  List<Widget> get _pages => [
  _buildStreamTab(),
  _buildClassworkTab(
    onNewAssignment: (assignment) {
      // เมื่อมี Assignment ใหม่ ส่งไปเพิ่มใน Stream
      _addAnnouncement({
        'author': assignment['author'] ?? 'Instructor',
        'text': '${assignment['title']}\n${assignment['description']}',
        'datetime': DateFormat('d MMM yyyy, HH:mm').format(DateTime.now()),
      });
    },
  ),
  _buildReportTab(),
  _buildPeopleTab(),
];

  Widget _buildStreamTab() {
    final course = widget.course;
    return Padding(
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
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AnnouncementDetailPage(announcement: a),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  backgroundImage: AssetImage(
                                    'assets/profile.jpg',
                                  ),
                                  radius: 28,
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
                                    if (value == 'edit')
                                      _editAnnouncement(i);
                                    else if (value == 'delete')
                                      _deleteAnnouncement(i);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              a['text'] ?? '',
                              style: const TextStyle(fontSize: 15, height: 1.5),
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
    );
  }

  Widget _buildClassworkTab({required void Function(Map<String, String>) onNewAssignment}) {
  return ClassworkPage(
    assignments: assignments,
    onNewAssignment: _addAssignment, // ส่ง callback ที่รับเข้ามาโดยตรง
  );
}


  Widget _buildReportTab() => const ReportPage();

  Widget _buildPeopleTab() => const PeoplePage();

  @override
  Widget build(BuildContext context) {
    final course = widget.course;

    return Scaffold(
      appBar: AppBar(title: Text(course['title'] ?? 'Course Detail')),
      body: _pages[_selectedIndex], // แสดงหน้าแท็บที่เลือก
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Stream',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Classwork',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'People',
          ),
        ],
      ),
    );
  }
}
