import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/models/feed_item.dart';
import 'package:frontend/services/feed_service.dart';
import 'package:frontend/widgets/feed_cards.dart';
import 'package:frontend/widgets/active_sessions_banner.dart';
import 'package:frontend/utils/location_helper.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/attendance_service.dart';
import 'package:frontend/screens/student_checkin_screen.dart';
import 'package:frontend/screens/classroom_home_screen.dart';

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
      body: _buildBody(),
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
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _StudentStreamTab(
          classId: widget.classId,
          className: widget.className,
          teacherName: widget.teacherName,
        );
      case 1:
        return _StudentClassworkTab(classId: widget.classId);
      case 2:
        return const _StudentReportTab();
      case 3:
        return _StudentPeopleTab(teacherName: widget.teacherName);
      default:
        return const SizedBox.shrink();
    }
  }
}

/// ======================
/// 🔹 STREAM TAB (ฟีดเช็คชื่อ/ประกาศ)
/// ======================
class _StudentStreamTab extends StatefulWidget {
  final String classId;
  final String className;
  final String teacherName;
  const _StudentStreamTab({
    required this.classId,
    required this.className,
    required this.teacherName,
  });

  @override
  State<_StudentStreamTab> createState() => _StudentStreamTabState();
}

class _StudentStreamTabState extends State<_StudentStreamTab> {
  late Future<List<FeedItem>> _futureFeed;

  @override
  void initState() {
    super.initState();
    _futureFeed = FeedService.getClassFeed(widget.classId);
  }

  Future<void> _refresh() async {
    setState(() {
      _futureFeed = FeedService.getClassFeed(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final className = widget.className;
    final teacherName = widget.teacherName;
    final classId = widget.classId;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header การ์ดห้องเรียน
          Card(
            color: getClassColor(className),
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
                    className,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Teacher: $teacherName'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // แบนเนอร์เช็คชื่อที่กำลังเปิด (นักเรียน)
          //ActiveSessionsBanner(classId: classId, isTeacherView: false),

          const SizedBox(height: 16),
          Text('Announcements', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          // ✅ ฟีด Stream จริง (feed_cards)
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
                isTeacher: false,
                classId: classId,
                onChanged: _refresh,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ======================
/// 🔹 CLASSWORK TAB (งาน/Assignment)
/// ======================
class _StudentClassworkTab extends StatefulWidget {
  final String classId;
  const _StudentClassworkTab({required this.classId});

  @override
  State<_StudentClassworkTab> createState() => _StudentClassworkTabState();
}

class _StudentClassworkTabState extends State<_StudentClassworkTab> {
  late Future<List<FeedItem>> _futureAssignments;

  @override
  void initState() {
    super.initState();
    _futureAssignments = FeedService.getClassFeed(widget.classId);
  }

  Future<void> _refresh() async {
    setState(() {
      _futureAssignments = FeedService.getClassFeed(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<FeedItem>>(
        future: _futureAssignments,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snap.error}'));
          }

          final feed = snap.data ?? [];
          // ✅ กรองเฉพาะ feed ที่เป็น assignment
          final assignments = feed
              .where((f) => (f.extra['kind'] ?? '') == 'assignment')
              .toList();

          if (assignments.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('ยังไม่มีงานในคลาสนี้'),
              ),
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: FeedList(
              items: assignments,
              isTeacher: false,
              classId: widget.classId,
              onChanged: _refresh,
            ),
          );
        },
      ),
    );
  }
}

/// ======================
/// 🔹 REPORT TAB
/// ======================
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

/// ======================
/// 🔹 PEOPLE TAB
/// ======================
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
