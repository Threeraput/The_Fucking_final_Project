import 'package:flutter/material.dart';
import 'package:frontend/models/classroom.dart';
import 'package:frontend/models/users.dart';
import 'package:frontend/screens/create_announcement_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/class_service.dart';
import 'create_class_screen.dart';
import 'package:frontend/services/attendance_service.dart';
import 'package:frontend/screens/teacher_open_checkin_sheet.dart';
import 'package:frontend/screens/student_checkin_screen.dart'; //  เพิ่ม
import 'package:intl/intl.dart';

class ClassDetailsScreen extends StatefulWidget {
  final String classId;
  final String? className; // เผื่อส่งชื่อมาจาก Card

  const ClassDetailsScreen({super.key, required this.classId, this.className});

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
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
          setState(() {}); // รีเฟรช Stream -> Active sessions
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
        selectedItemColor: const Color.fromARGB(
          255,
          65,
          171,
          179,
        ), // 🔹 สีไอคอนและข้อความที่เลือก
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

class _StreamTab extends StatelessWidget {
  final String classId; // ✅ เพิ่ม
  final Classroom? classroom;
  final bool isTeacher;
  final VoidCallback onCreateAnnouncement;

  const _StreamTab({
    required this.classId,
    required this.classroom,
    required this.isTeacher,
    required this.onCreateAnnouncement,
  });

  @override
  Widget build(BuildContext context) {
    final c = classroom;
    return RefreshIndicator(
      onRefresh: () async {
        // ไว้รีเฟรชประกาศ เมื่อมี service ประกาศ
        await Future.delayed(const Duration(milliseconds: 400));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (c != null)
            Card(
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
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Code: ${c.code ?? '-'}'),
                    const SizedBox(height: 4),
                    Text(
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

          // ✅ แสดง Active Sessions ของคลาสนี้ (ครู: เปิดใหม่, นร.: เช็คชื่อ)
          const SizedBox(height: 12),
          _ActiveSessionsSection(classId: classId, isTeacher: isTeacher),

          if (isTeacher) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onCreateAnnouncement,
              icon: const Icon(Icons.campaign),
              label: const Text('Create Announcement'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Announcements', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          // TODO: แสดงรายการประกาศจริงเมื่อมี service
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No announcements yet.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
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

/// ======================
/// Active Sessions Section
/// ======================
class _ActiveSessionsSection extends StatefulWidget {
  final String classId;
  final bool isTeacher;
  const _ActiveSessionsSection({
    required this.classId,
    required this.isTeacher,
  });

  @override
  State<_ActiveSessionsSection> createState() => _ActiveSessionsSectionState();
}

class _ActiveSessionsSectionState extends State<_ActiveSessionsSection> {
  late Future<List<Map<String, dynamic>>> _futureSessions;

  @override
  void initState() {
    super.initState();
    _futureSessions = _loadSessions();
  }

  Future<List<Map<String, dynamic>>> _loadSessions() async {
    final all = await AttendanceService.getActiveSessions();
    return all
        .where((m) => (m['class_id']?.toString() ?? '') == widget.classId)
        .toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureSessions = _loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureSessions,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'ไม่สามารถโหลด Session ได้: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          if (widget.isTeacher) {
            return Card(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('ยังไม่มีการเปิดเช็คชื่อ')),
                    FilledButton.icon(
                      onPressed: () async {
                        final opened = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) =>
                              TeacherOpenCheckinSheet(classId: widget.classId),
                        );
                        if (opened == true) _refresh();
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('เปิดเช็คชื่อ'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        // มี session -> แสดงการ์ดทั้งหมด
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เช็คชื่อที่กำลังเปิดอยู่',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...sessions.map(
              (s) => _ActiveSessionCard(
                data: s,
                isTeacher: widget.isTeacher,
                classId: widget.classId,
                onRefetch: _refresh,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isTeacher;
  final String classId;
  final Future<void> Function() onRefetch;

  const _ActiveSessionCard({
    required this.data,
    required this.isTeacher,
    required this.classId,
    required this.onRefetch,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('HH:mm');
    final expiresAt = DateTime.tryParse(data['expires_at']?.toString() ?? '');
    final expTxt = expiresAt != null
        ? 'หมดอายุ ${df.format(expiresAt.toLocal())}'
        : 'ไม่ทราบเวลา';
    final radius = data['radius_meters']?.toString() ?? '-';
    final lat = data['anchor_lat']?.toString() ?? '-';
    final lon = data['anchor_lon']?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.access_time),
        title: const Text('Session กำลังเปิดอยู่'),
        subtitle: Text('$expTxt · รัศมี $radius m\nAnchor: $lat, $lon'),
        trailing: isTeacher
            ? FilledButton(
                onPressed: () async {
                  final opened = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TeacherOpenCheckinSheet(classId: classId),
                  );
                  if (opened == true) onRefetch();
                },
                child: const Text('เปิดใหม่'),
              )
            : FilledButton(
                onPressed: () async {
                  final ok = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentCheckinScreen(classId: classId),
                    ),
                  );
                  if (ok == true) onRefetch();
                },
                child: const Text('เช็คชื่อ'),
              ),
      ),
    );
  }
}
