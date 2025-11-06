import 'package:flutter/material.dart';
import 'package:frontend/models/classroom.dart';
import 'package:frontend/models/classwork.dart';
import 'package:frontend/models/users.dart';
import 'package:frontend/services/class_service.dart';
import 'package:frontend/services/classwork_simple_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import "../services/auth_service.dart"; 

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;
  final String title;
  final String? classId;
  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    required this.title,
    this.classId,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  late Future<List<ClassworkSubmission>> _future;
  final _scoreControllers = <String, TextEditingController>{};
  final Map<String, User> _userIndex = {};

  @override
  void initState() {
    super.initState();
    _future = ClassworkSimpleService.getSubmissionsForAssignment(
      widget.assignmentId,
    );
    _loadUsersIfNeeded();
  }

  Future<void> _loadUsersIfNeeded() async {
    if (widget.classId == null) return; // ไม่มี classId ก็ข้าม
    try {
      final Classroom cls = await ClassService.getClassroomDetails(
        widget.classId!,
      );
      // เก็บ students เข้าดัชนี
      for (final u in cls.students) {
        _userIndex[u.userId] = u;
      }
      if (mounted) setState(() {}); // ให้หน้าจอรีเฟรชชื่อ
    } catch (e) {
      // ไม่เป็นไร ถ้าดึงรายชื่อไม่ได้ จะ fallback ด้านล่าง
    }
  }

  String _displayName(String studentId) {
    final u = _userIndex[studentId];
    if (u != null) {
      final fn = (u.firstName ?? '').trim();
      final ln = (u.lastName ?? '').trim();
      final full = [fn, ln].where((s) => s.isNotEmpty).join(' ');
      if (full.isNotEmpty) return full;
      if ((u.username).isNotEmpty) return u.username;
    }
    return studentId;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = ClassworkSimpleService.getSubmissionsForAssignment(
        widget.assignmentId,
      );
    });
  }

  Future<void> _saveScore({
    required String assignmentId,
    required String studentId,
    required String score,
  }) async {
    try {
      final parsedScore = int.tryParse(score) ?? 0;
      await ClassworkSimpleService.gradeSubmission(
        assignmentId: assignmentId,
        studentId: studentId,
        score: parsedScore,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกคะแนนเรียบร้อย')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }
  }

  ///  ฟังก์ชันเปิดไฟล์ PDF ที่แน่ใจว่า URL ถูกต้อง 100%
  Future<void> _openSubmissionFile(String urlOrPath) async {
    final resolvedUrl = _resolveFileUrl(urlOrPath);
    final uri = Uri.tryParse(resolvedUrl);

    print('🧩 Raw: $urlOrPath');
    print('✅ Fixed: $resolvedUrl');

    //  ถ้า URL ถูกต้อง (http/https) ให้เปิดทันที
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเปิดไฟล์: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('URL ไม่ถูกต้อง: $resolvedUrl')));
    }
  }

  ///  ฟังก์ชัน normalize URL (แก้ให้มี http:// และตัด static ออก)
  String _resolveFileUrl(String relativePath) {
    const base = 'http://192.168.0.197:8000'; // ✅ ใส่ http:// ด้วย
    var path = relativePath.trim();

    // ถ้าเป็น URL เต็มแล้ว ก็ส่งกลับเลย
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // ตัด static/ ออกถ้ามี
    if (path.contains('static/')) {
      path = path.replaceFirst('static/', '');
    }

    // เพิ่ม workpdf/ ถ้าไม่มี
    if (!path.startsWith('workpdf/')) {
      path = 'workpdf/$path';
    }

    return '$base/$path';
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy, HH:mm');
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ClassworkSubmission>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) { // การโหลด loading
              return const Center(child: CircularProgressIndicator(
                color: Colors.blue,
              ));
            }
            if (snap.hasError) {
              return Center(child: Text('โหลดข้อมูลไม่สำเร็จ: ${snap.error}'));
            }
            final subs = snap.data ?? [];
            if (subs.isEmpty) {
              return const Center(child: Text('ยังไม่มีนักเรียนส่งงาน'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: subs.length,
              itemBuilder: (context, i) {
                final s = subs[i];
                final c = _scoreControllers.putIfAbsent(
                  s.submissionId,
                  () => TextEditingController(text: s.score?.toString() ?? ''),
                );

                return Card(
  elevation: 2,
  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ชื่อผู้เรียน
        Text(
          'นักเรียน: ${_displayName(s.studentId)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),

        // วันที่ส่ง
        if (s.submittedAt != null)
          Text.rich(
            TextSpan(
              text: 'ส่งเมื่อ: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
              children: [
                TextSpan(
                  text: df.format(s.submittedAt!),
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),

        // สถานะ
        Text.rich(
          TextSpan(
            text: 'สถานะ: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
            children: [
              TextSpan(
                text: s.submissionStatus.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: s.submissionStatus.name == 'ส่งแล้ว'
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ปุ่มเปิดไฟล์
        if (s.contentUrl != null)
          FilledButton.tonal(
            onPressed: () => _openSubmissionFile(s.contentUrl!),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.file_open_outlined, color: Colors.blueAccent),
                SizedBox(width: 6),
                Text(
                  'เปิดไฟล์งานที่ส่ง',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // ส่วนให้คะแนน
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: c,
                decoration: InputDecoration(
                  labelText: 'คะแนน',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.save, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.all(14),
              ),
              onPressed: () {
                _saveScore(
                  assignmentId: widget.assignmentId,
                  studentId: s.studentId,
                  score: c.text,
                );
              },
            ),
          ],
        ),
      ],
    ),
  ),
);

              },
            );
          },
        ),
      ),
    );
  }
}
