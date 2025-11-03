import 'package:flutter/material.dart';
import 'package:frontend/models/classroom.dart';
import 'package:frontend/models/users.dart';
import 'package:frontend/screens/classroom_home_screen.dart';
import 'package:frontend/screens/create_announcement_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/class_service.dart';
import 'package:frontend/screens/teacher_open_checkin_sheet.dart';
import 'package:frontend/services/feed_service.dart';
import 'package:frontend/widgets/feed_cards.dart';
import 'package:frontend/models/feed_item.dart';

class ClassDetailsScreen extends StatefulWidget {
  final String classId;
  final String? className; // เผื่อส่งชื่อมาจาก Card

  const ClassDetailsScreen({super.key, required this.classId, this.className});

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  final GlobalKey<_StreamTabState> _streamKey = GlobalKey<_StreamTabState>();
  int _currentIndex = 0;
  bool _loading = true;
  bool _error = false;
  bool _isTeacher = false;

  Classroom? _classroom;
  User? _me;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final me = await AuthService.getCurrentUserFromLocal();
      final isTeacher =
          me?.roles.contains('teacher') == true ||
          me?.roles.contains('admin') == true;
      Classroom? cls;
      if (isTeacher) {
        // teacher/admin เข้าถึงรายละเอียดคลาสได้
        cls = await ClassService.getClassroomDetails(widget.classId);
      }
      setState(() {
        _me = me;
        _isTeacher = isTeacher;
        _classroom = cls;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  void _openCreateAnnouncement() async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAnnouncementScreen(
          classId: widget.classId,
          className: _classroom?.name ?? widget.className ?? 'Class',
        ),
      ),
    );

    // ✅ หลังประกาศ ถ้าเป็นครู ให้ถามว่าจะเปิดเช็คชื่อต่อเลยไหม
    if (ok == true && _isTeacher && mounted) {
      final wantOpen = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('เปิดเช็คชื่อต่อเลยไหม?'),
          content: const Text(
            'คุณเพิ่งประกาศแล้ว ต้องการเปิด session เช็คชื่อสำหรับคลาสนี้ตอนนี้เลยหรือไม่',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ภายหลัง'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('เปิดเลย'),
            ),
          ],
        ),
      );
     if (wantOpen == true) {
        final opened = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          builder: (_) => TeacherOpenCheckinSheet(classId: widget.classId),
        );
        if (opened == true && mounted) {
          _streamKey.currentState
              ?.refreshFeed(); // เรียกแบบ force ผ่านเมธอดนี้แล้ว
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('เปิดเช็คชื่อแล้ว')));
        }
      }
    }

    // TODO: ถ้ามี service ประกาศแล้ว ให้ refresh feed ได้ที่นี่
  }

  @override
  Widget build(BuildContext context) {
    final title = _classroom?.name ?? widget.className ?? 'Classroom';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
          ? const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'))
          : _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(
          255,
          255,
          255,
          255,
        ), // 🔹 พื้นหลัง
        selectedItemColor: Colors.blueAccent, // 🔹 สีไอคอนและข้อความที่เลือก
        unselectedItemColor: const Color.fromARGB(
          255,
          39,
          39,
          39,
        ), // 🔹 สีไอคอนที่ไม่ได้เลือก
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
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

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _StreamTab(
          key: _streamKey,
          classId: widget.classId, // ✅ ส่ง classId เข้าไป
          classroom: _classroom,
          isTeacher: _isTeacher,
          onCreateAnnouncement: _openCreateAnnouncement,
        );
      case 1:
        return const _ClassworkTab();
      case 2:
        return const _ReportTab();
      case 3:
        return _PeopleTab(classroom: _classroom);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StreamTab extends StatefulWidget {
  final String classId;
  final Classroom? classroom;
  final bool isTeacher;
  final VoidCallback onCreateAnnouncement;

  const _StreamTab({
    Key? key, // ✅ รับ key
    required this.classId,
    required this.classroom,
    required this.isTeacher,
    required this.onCreateAnnouncement,
  }) : super(key: key);

  @override
  State<_StreamTab> createState() => _StreamTabState();
}

class _StreamTabState extends State<_StreamTab> {
  late Future<List<FeedItem>> _futureFeed;

  // เก็บฟีดล่าสุดไว้ในหน่วยความจำ (เพื่อใส่การ์ดแบบทันที)
  List<FeedItem> _lastFeed = const [];

  @override
  void initState() {
    super.initState();
    _futureFeed = FeedService.getClassFeed(widget.classId).then((list) {
      _lastFeed = list;
      return list;
    });
  }

  Future<void> _refresh({bool force = false}) async {
    setState(() {
      _futureFeed = FeedService.getClassFeed(widget.classId, force: force).then(
        (list) {
          _lastFeed = list; // sync state ในหน่วยความจำ
          return list;
        },
      );
    });
  }

  void refreshFeed() => _refresh(force: true);

  /// ใส่การ์ด session ใหม่แบบ optimistic (แสดงทันทีโดยไม่ต้องรูดรีเฟรช)
  void insertOptimisticSession(Map<String, dynamic> s) {
    final id = s['session_id']?.toString() ?? s['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final start = DateTime.tryParse(s['start_time']?.toString() ?? '');
    final end = DateTime.tryParse(
      s['end_time']?.toString() ?? s['expires_at']?.toString() ?? '',
    );

    final item = FeedItem(
      id: id,
      classId: widget.classId,
      type: FeedType.checkin,
      title: 'เช็คชื่อกำลังเปิดอยู่',
      postedAt: start ?? DateTime.now(),
      expiresAt: end,
      extra: {
        'session_id': id,
        'reverify_enabled': s['reverify_enabled'] == true,
        'radius': s['radius_meters'],
        'anchor_lat': s['anchor_lat'],
        'anchor_lon': s['anchor_lon'],
      },
    );

    setState(() {
      _lastFeed = [item, ..._lastFeed]; // ใส่บนสุด
      _futureFeed = Future.value(_lastFeed); // ให้ FutureBuilder อัปเดตทันที
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.classroom;
    return RefreshIndicator(
      // รูดรีเฟรช -> เอาแบบ force กันแคชไปเลย
      onRefresh: () => _refresh(force: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (c != null)
            Card(
              color: getClassColor(c.name ?? 'Class'),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name ?? '—',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text('Code: ${c.code ?? '-'}'),
                    const SizedBox(height: 4),
                    Text(
                      style: const TextStyle(color: Colors.white70),
                      'Teacher: ${c.teacher?.username ?? c.teacher?.email ?? '-'}',
                    ),
                    if ((c.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(c.description!),
                    ],
                  ],
                ),
              ),
            ),

          // ปุ่มฝั่งครู
          if (widget.isTeacher) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: widget.onCreateAnnouncement,
              icon: const Icon(Icons.campaign),
              label: const Text('Create Announcement'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black38, // สีข้อความและไอคอน
                minimumSize: const Size.fromHeight(44),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blueAccent, // สีพื้นหลัง
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () async {
                final created =
                    await showModalBottomSheet<Map<String, dynamic>?>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) =>
                          TeacherOpenCheckinSheet(classId: widget.classId),
                    );

                if (!mounted) return;

                if (created != null) {
                  // 1) โชว์ทันที (optimistic)
                  
                  if (!mounted) return;
                  await Future.delayed(const Duration(seconds: 2));
                  insertOptimisticSession(created);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('เปิดเช็คชื่อแล้ว')),
                  );
                  await _refresh(force: true);
                }
              },
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('ประกาศเช็คชื่อ'),
            ),
          ],

          const SizedBox(height: 16),
          Text('Announcements', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          FutureBuilder<List<FeedItem>>(
            future: _futureFeed,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('โหลดฟีดไม่สำเร็จ: ${snap.error}'),
                  ),
                );
              }
              final feed = snap.data ?? const <FeedItem>[];
              return FeedList(
                items: feed,
                isTeacher: widget.isTeacher,
                classId: widget.classId,
               onChanged: () => _refresh(force: true),// เปลี่ยนเป็น force ทุกครั้ง
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ClassworkTab extends StatelessWidget {
  const _ClassworkTab();

  @override
  Widget build(BuildContext context) {
    // TODO: อาจารย์สร้างงาน/นักเรียนดูงาน-ส่งงาน เมื่อมี API พร้อม
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Classwork — สร้าง/ส่งงาน จะอยู่ที่นี่',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ReportTab extends StatelessWidget {
  const _ReportTab();

  @override
  Widget build(BuildContext context) {
    // TODO: แสดงสถิติขาด/ลา/มาสายจาก API report
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Report — สถิติการเช็คชื่อ จะอยู่ที่นี่',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PeopleTab extends StatelessWidget {
  final Classroom? classroom;
  const _PeopleTab({required this.classroom});

  @override
  Widget build(BuildContext context) {
    final c = classroom;
    if (c == null) {
      return const Center(child: Text('ไม่มีข้อมูลสมาชิกในคลาส'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Teacher', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(c.teacher?.username ?? c.teacher?.email ?? '-'),
          subtitle: Text(c.teacher?.email ?? ''),
        ),
        const SizedBox(height: 12),
        Text(
          'Students (${c.students.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (c.students.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('ยังไม่มีนักเรียน'),
            ),
          ),
        ...c.students.map(
          (s) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(s.username ?? s.email ?? '-'),
            subtitle: Text(s.email ?? ''),
          ),
        ),
      ],
    );
  }
}
