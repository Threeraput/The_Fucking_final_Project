import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/screens/student_reverify_screen.dart';
import 'package:frontend/utils/location_helper.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/attendance_service.dart';
import 'package:frontend/screens/student_checkin_screen.dart';
import "package:frontend/screens/classroom_home_screen.dart";
import 'package:frontend/widgets/active_sessions_banner.dart';


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
        ActiveSessionsBanner(
          classId: classId,
          isTeacherView: false, // หน้านักเรียน
        ),

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
