import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/screens/student_reverify_screen.dart';
import 'package:frontend/utils/location_helper.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/attendance_service.dart';
import 'package:frontend/screens/student_checkin_screen.dart';
import "package:frontend/screens/classroom_home_screen.dart";

class StudentClassView extends StatefulWidget {
  final String classId; // <- ต้องเป็น UUID ของคลาส
  final String className;
  final String teacherName;

  const StudentClassView({
    super.key,
    required this.classId,
    required this.className,
    required this.teacherName,
  });

  @override
  State<StudentClassView> createState() => _StudentClassViewState();
}

class _StudentClassViewState extends State<StudentClassView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.className)),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        selectedItemColor: const Color.fromARGB(255, 65, 171, 179),
        unselectedItemColor: const Color.fromARGB(255, 39, 39, 39),
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _StudentStreamTab(
          classId: widget.classId, // ✅ ส่ง classId เข้ามาใช้กรอง
          className: widget.className,
          teacherName: widget.teacherName,
        );
      case 1:
        return const _StudentClassworkTab();
      case 2:
        return const _StudentReportTab();
      case 3:
        return _StudentPeopleTab(teacherName: widget.teacherName);
      default:
        return const SizedBox.shrink();
    }
  }
}

final color = getClassColor('Example Class'); // ตัวอย่างการใช้ฟังก์ชัน

class _StudentStreamTab extends StatelessWidget {
  final String classId;
  final String className;
  final String teacherName;
  const _StudentStreamTab({
    required this.classId,
    required this.className,
    required this.teacherName,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: getClassColor(className), // ใช้ฟังก์ชันใหม่
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(className, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Teacher: $teacherName'),
              ],
            ),
          ),
        ),

        // 🔹 แสดง Active Sessions สำหรับคลาสนี้
        const SizedBox(height: 12),
        _StudentActiveSessionsSection(classId: classId),

        const SizedBox(height: 16),
        Text('Announcements', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No announcements yet.'),
          ),
        ),
      ],
    );
  }
}

class _StudentClassworkTab extends StatelessWidget {
  const _StudentClassworkTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Classwork — งานที่ได้รับมอบหมายจะอยู่ที่นี่',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _StudentReportTab extends StatelessWidget {
  const _StudentReportTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Report — สถิติการเข้าเรียนของฉันจะอยู่ที่นี่',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _StudentPeopleTab extends StatelessWidget {
  final String teacherName;
  const _StudentPeopleTab({required this.teacherName});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Teacher', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(teacherName),
        ),
        const SizedBox(height: 12),
        Text('Students', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('จะแสดงรายชื่อเพื่อนร่วมชั้นเมื่อ API พร้อม'),
          ),
        ),
      ],
    );
  }
}

/// ===========================================
/// Active Sessions (Student) - auto refresh + check-in button
/// ===========================================
class _StudentActiveSessionsSection extends StatefulWidget {
  final String classId;
  const _StudentActiveSessionsSection({required this.classId});

  @override
  State<_StudentActiveSessionsSection> createState() =>
      _StudentActiveSessionsSectionState();
}

class _StudentActiveSessionsSectionState
    extends State<_StudentActiveSessionsSection> {
  late Future<List<Map<String, dynamic>>> _future;
  Timer? _timer;
  String? sessionId;

  @override
  void initState() {
    super.initState();
    _future = _load();
    // 🔁 auto-refresh ทุก 20 วินาที
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      setState(() => _future = _load());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final all = await AttendanceService.getActiveSessions();

    // 🔎 ถ้าต้องการ debug โครง JSON จริง เปิดบรรทัดนี้
    // ignore: avoid_print
    // print('🛰️ active sessions raw: ${all.length} -> $all');

    String? _extractClassId(Map<String, dynamic> s) {
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

    return all.where((m) => _extractClassId(m) == widget.classId).toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'โหลดสถานะเช็คชื่อไม่สำเร็จ: ${snap.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        final sessions = snap.data ?? const [];
        if (sessions.isEmpty) {
          return Card(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 12),
                  Expanded(child: Text('ยังไม่มีการเปิดเช็คชื่อในขณะนี้')),
                ],
              ),
            ),
          );
        }

        final df = DateFormat('HH:mm');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เช็คชื่อที่กำลังเปิดอยู่',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...sessions.map((s) {
              final sessionId = (s['session_id'] ?? s['id'] ?? s['sessionId'])
                  ?.toString();
              // เวลา/รายละเอียด (กัน null)
              final expStr = s['expires_at']?.toString();
              DateTime? exp;
              try {
                exp = expStr != null ? DateTime.tryParse(expStr) : null;
              } catch (_) {}
              final expTxt = exp != null ? df.format(exp.toLocal()) : '-';

              final radius = s['radius_meters']?.toString();
              final lat = s['anchor_lat']?.toString();
              final lon = s['anchor_lon']?.toString();

              final subtitle = [
                if (exp != null) 'หมดอายุ: $expTxt',
                if (radius != null) 'รัศมี $radius m',
                if (lat != null && lon != null) 'Anchor: $lat, $lon',
              ].join(' · ');

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text(
                    style: TextStyle(fontSize: 16),
                    'Session กำลังเปิดอยู่',
                  ),
                  subtitle: Text(subtitle.isEmpty ? '-' : subtitle),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      // ปุ่มเช็คชื่อ (เดิม)
                      FilledButton(
                        onPressed: () async {
                          final ok = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudentCheckinScreen(classId: widget.classId),
                            ),
                          );
                          if (ok == true) _refresh();
                        },
                        child: const Text('เช็คชื่อ'),
                      ),

                      // 🔹 ปุ่มยืนยันซ้ำ (ใช้ VerifyFaceRoute)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.verified_user_outlined),
                        label: const Text('ยืนยันซ้ำ'),
                        onPressed: () async {
                          final sessionId =
                              (s['session_id'] ?? s['id'] ?? s['sessionId'])
                                  ?.toString();
                          if (sessionId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ไม่พบ session_id')),
                            );
                            return;
                          }

                          try {
                            //  1) เปิดหน้า VerifyFaceRoute ในโหมด reverify
                            final result = await Navigator.pushNamed(
                              context,
                              '/reverify-face',
                            );

                            if (result == null ||
                                result is! String ||
                                result.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ยกเลิกการยืนยันซ้ำ'),
                                ),
                              );
                              return;
                            }

                            final imagePath = result;

                            //  2) ดึงพิกัด GPS
                            final pos =
                                await LocationHelper.getCurrentPositionOrThrow();

                            // 📡 3) ส่งข้อมูลไปยัง API /attendance/re-verify
                            await AttendanceService.reVerify(
                              sessionId: sessionId,
                              imagePath: imagePath,
                              latitude: pos.latitude,
                              longitude: pos.longitude,
                            );

                            if (!context.mounted) return;
                            // ✅ 4) แจ้งผลและรีเฟรช
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ยืนยันตัวตนซ้ำสำเร็จ'),
                              ),
                            );
                            _refresh();
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'เกิดข้อผิดพลาด: ${e.toString()}',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
