import 'package:flutter/material.dart';
import 'package:frontend/models/classroom.dart';
import 'package:frontend/models/users.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/class_service.dart';
import 'create_class_screen.dart';

class ClassDetailsScreen extends StatefulWidget {
  final String classId;
  const ClassDetailsScreen({super.key, required this.classId});

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  late Future<Classroom> _future;
  User? _me;

  bool get _isTeacher =>
      _me?.roles.contains('teacher') == true ||
      _me?.roles.contains('admin') == true;

  @override
  void initState() {
    super.initState();
    _future = ClassService.getClassroomDetails(widget.classId);
    _loadMe();
  }

  Future<void> _loadMe() async {
    final u = await AuthService.getCurrentUserFromLocal();
    setState(() => _me = u);
  }

  Future<void> _refresh() async {
    setState(() => _future = ClassService.getClassroomDetails(widget.classId));
  }

  Future<void> _removeStudent(String studentId) async {
    try {
      await ClassService.removeStudent(widget.classId, studentId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ลบนักเรียนแล้ว')));
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
      }
    }
  }

  Future<void> _deleteClass() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบคลาสนี้?'),
        content: const Text('การลบนี้เป็นการลบถาวร'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ClassService.deleteClassroom(widget.classId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
      }
    }
  }

  Future<void> _editClass(Classroom c) async {
    final updated = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CreateClassScreen(editing: c)));
    if (updated != null) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดคลาส'),
        actions: [
          if (_isTeacher)
            IconButton(onPressed: _deleteClass, icon: const Icon(Icons.delete)),
        ],
      ),
      body: FutureBuilder<Classroom>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            return const Center(child: CircularProgressIndicator());
          }
          final c = snap.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Banner เหมือน Google Classroom
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primary.withOpacity(0.9),
                        primary.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        top: -10,
                        child: Icon(
                          Icons.class_,
                          size: 120,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name ?? '(no name)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _pill(Icons.key, c.code ?? '-'),
                              const SizedBox(width: 8),
                              _pill(
                                Icons.person_outline,
                                c.teacher?.username ?? c.teacher?.email ?? '-',
                              ),
                              const Spacer(),
                              if (_isTeacher)
                                IconButton(
                                  onPressed: () => _editClass(c),
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // เนื้อหา
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((c.description ?? '').isNotEmpty) ...[
                        Text(
                          'คำอธิบาย',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(c.description!),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'นักเรียน (${c.students.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (c.students.isEmpty)
                        const Text('ยังไม่มีนักเรียนในคลาสนี้')
                      else
                        ...c.students.map(
                          (s) => Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(s.username ?? s.email ?? s.userId),
                              subtitle: Text(s.roles.join(', ')),
                              trailing: _isTeacher
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: () => _removeStudent(s.userId),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
