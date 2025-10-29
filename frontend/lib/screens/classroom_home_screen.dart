import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:frontend/models/users.dart';
import 'package:frontend/models/classroom.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/class_service.dart';
import 'class_details_screen.dart';
import 'create_class_screen.dart';
import 'join_class_sheet.dart';
import 'student_class_view.dart';
import '../screens/camera_screen.dart';
import '../services/face_service.dart';

class ClassroomHomeScreen extends StatefulWidget {
  const ClassroomHomeScreen({super.key});

  @override
  State<ClassroomHomeScreen> createState() => _ClassroomHomeScreenState();
}

class _ClassroomHomeScreenState extends State<ClassroomHomeScreen> {
  User? _me;
  Future<List<Classroom>>? _futureTaught;
  Future<List<Classroom>>? _futureJoined;

  bool get _isTeacher =>
      _me?.roles.contains('teacher') == true ||
      _me?.roles.contains('admin') == true;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    final u = await AuthService.getCurrentUserFromLocal();
    setState(() {
      _me = u;
      if (_isTeacher) {
        _futureTaught = ClassService.getTaughtClasses();
      } else {
        _futureJoined = ClassService.getJoinedClasses();
      }
    });
  }

  Future<void> _refresh() async {
    setState(() {
      if (_isTeacher) {
        _futureTaught = ClassService.getTaughtClasses();
      } else {
        _futureJoined = ClassService.getJoinedClasses();
      }
    });
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreateClassScreen()));
    if (created == true) {
      _refresh(); //  รีเฟรชทันทีเมื่อสร้างสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('สร้างคลาสสำเร็จ')));
      }
    }
  }

  Future<void> _openJoin() async {
    final joined = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const JoinClassSheet(),
    );
    if (joined == true) {
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('เข้าร่วมคลาสสำเร็จ')));
      }
    }
  }

  Drawer _buildDrawer() {
    final me = _me;

    // ถ้ายังโหลดข้อมูล user ไม่เสร็จ — ไม่แสดง Drawer
    if (me == null) {
      return const Drawer(child: Center(child: CircularProgressIndicator()));
    }

    // เช็คว่าเป็น student หรือไม่
    final isStudent = me.roles.any((r) => r.toLowerCase() == 'student');

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // 🔹 ส่วนหัว
            UserAccountsDrawerHeader(
              accountName: Text(me.username ?? 'ไม่ทราบชื่อ'),
              accountEmail: Text(me.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.deepOrangeAccent,
                child: Text(
                  (me.username?.isNotEmpty == true ? me.username![0] : '?')
                      .toUpperCase(),
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // 🔹 เมนูหลัก
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.class_),
                    title: Text(_isTeacher ? 'คลาสที่สอน' : 'คลาสที่เรียน'),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('ปฏิทิน'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: const Text('สิ่งที่ต้องทำ'),
                    onTap: () {},
                  ),
                  const Divider(),

                  // 🔹 เมนูเฉพาะอาจารย์
                  if (_isTeacher)
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: const Text('สร้างคลาสใหม่'),
                      onTap: () {
                        Navigator.pop(context);
                        _openCreate();
                      },
                    ),

                  // 🔹 เมนูเฉพาะนักเรียน
                  if (!_isTeacher)
                    ListTile(
                      leading: const Icon(Icons.group_add),
                      title: const Text('เข้าร่วมคลาส'),
                      onTap: () {
                        Navigator.pop(context);
                        _openJoin();
                      },
                    ),

                  // 🔹 เพิ่ม/ลบใบหน้า — เฉพาะนักเรียน
                  if (isStudent) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.face_retouching_natural),
                      title: const Text('เพิ่มใบหน้า'),
                      onTap: () async {
                        Navigator.pushReplacementNamed(context, '/upload-face');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever),
                      title: const Text('ลบใบหน้า'),
                      onTap: () async {
                        Navigator.pop(context);

                        final confirmed = await showDialog<bool>(
                          context: context,

                          builder: (ctx) { //แบบ responsive เเล้ว
                            // ดึงขนาดหน้าจอ
                            final screenWidth = MediaQuery.of(ctx).size.width;

                            // ปรับขนาดอักษรและระยะห่างตามขนาดหน้าจอ
                            final titleFontSize = screenWidth * 0.045;
                            final contentFontSize = screenWidth * 0.04;
                            final buttonFontSize = screenWidth * 0.04;
                            final paddingSize = screenWidth * 0.04;

                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: Text(
                                'ยืนยันการลบข้อมูลใบหน้า',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: titleFontSize,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              content: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: paddingSize * 0.5,
                                ),
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: contentFontSize,
                                      height: 1.4,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text:
                                            'คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลใบหน้าของคุณออกจากระบบ?\n',
                                      ),
                                      TextSpan(
                                        text: 'การกระทำนี้ ',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      TextSpan(
                                        text: 'ไม่สามารถกู้คืนได้',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              actionsAlignment: MainAxisAlignment.spaceEvenly,
                              actionsPadding: EdgeInsets.only(
                                bottom: paddingSize * 0.5,
                              ),
                              actions: [
                                TextButton(
                                  style: ButtonStyle(
                                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                                  ),
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(
                                    'ยกเลิก',
                                    style: TextStyle(
                                      fontSize: buttonFontSize,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.06,
                                      vertical: screenWidth * 0.025,
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(
                                    'ลบ',
                                    style: TextStyle(
                                      fontSize: buttonFontSize,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmed == true) {
                          try {
                            await FaceService.deleteFace();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ลบข้อมูลใบหน้าสำเร็จ'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('ลบข้อมูลใบหน้าไม่สำเร็จ: $e'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),

            const Divider(),

            // 🔹 ปุ่มออกจากระบบ
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('ออกจากระบบ'),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog( 
                      title: const Text('ยืนยันการออกจากระบบ'),
                      content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('ยกเลิก'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('ออกจากระบบ'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await AuthService.logout();
                    if (context.mounted) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    return Scaffold(
      appBar: AppBar(title: const Text('Classroom')),
      drawer: _buildDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _isTeacher ? _openCreate : _openJoin,
        tooltip: _isTeacher ? 'สร้างคลาสใหม่' : 'เข้าร่วมคลาส',
        child: const Icon(Icons.add),
      ),
      body: me == null
          ? const Center(child: CircularProgressIndicator())
          : (_isTeacher
                ? _TeacherClasses(
                    futureTaught: _futureTaught,
                    onRefresh: _refresh,
                  )
                : _StudentClasses(
                    futureJoined: _futureJoined,
                    onRefresh: _refresh,
                  )),
    );
  }
}

class _TeacherClasses extends StatelessWidget {
  final Future<List<Classroom>>? futureTaught;
  final Future<void> Function() onRefresh;
  const _TeacherClasses({required this.futureTaught, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Classroom>>(
      future: futureTaught,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snap.error}'));
        }
        final data = snap.data ?? [];
        if (data.isEmpty) {
          return const _EmptyState(
            title: 'ยังไม่มีคลาสที่คุณสอน',
            subtitle: 'กดปุ่ม + เพื่อสร้างคลาสใหม่',
          );
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            itemBuilder: (_, i) =>
                _ClassCard(c: data[i], isTeacher: true, onRefresh: onRefresh),
          ),
        );
      },
    );
  }
}

class _StudentClasses extends StatelessWidget {
  final Future<List<Classroom>>? futureJoined;
  final Future<void> Function() onRefresh;
  const _StudentClasses({required this.futureJoined, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Classroom>>(
      future: futureJoined,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snap.error}'));
        }
        final data = snap.data ?? [];
        if (data.isEmpty) {
          return const _EmptyState(
            title: 'ยังไม่มีคลาสที่เข้าร่วม',
            subtitle: 'กด “เข้าร่วม” แล้วกรอกรหัสจากอาจารย์',
          );
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            itemBuilder: (_, i) =>
                _ClassCard(c: data[i], isTeacher: false, onRefresh: onRefresh),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? extra;
  const _EmptyState({required this.title, required this.subtitle, this.extra});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.class_,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            if (extra != null) ...[const SizedBox(height: 16), extra!],
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final Classroom c;
  final bool isTeacher;
  final Future<void> Function()? onRefresh;
  const _ClassCard({required this.c, required this.isTeacher, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final color = Colors.primaries[c.name.hashCode % Colors.primaries.length];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: color.shade400,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (isTeacher) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClassDetailsScreen(classId: c.classId!),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentClassView(
                  classId: c.classId ?? '',
                  className: c.name ?? '(no name)',
                  teacherName: c.teacher?.username ?? c.teacher?.email ?? '-',
                ),
              ),
            );
          }
        },
        child: Stack(
          children: [
            // 🔹 เพิ่ม popup menu ตรงนี้
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) async {
                  if (value == 'edit') {
                    // แก้ไขคลาส (เฉพาะอาจารย์)
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateClassScreen(editing: c),
                      ),
                    );
                    if (updated == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('แก้ไขคลาสสำเร็จ')),
                      );
                      onRefresh?.call();
                    }
                  } else if (value == 'delete') {
                    // ลบคลาส
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('ยืนยันการลบ'),
                        content: Text('ต้องการลบ "${c.name}" ใช่หรือไม่?'),
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
                    if (confirm == true) {
                      try {
                        await ClassService.deleteClassroom(c.classId!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ลบคลาสสำเร็จ')),
                          );
                          onRefresh?.call();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
                        );
                      }
                    }
                  } else if (value == 'leave') {
                    // นักเรียนออกจากคลาส
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('ออกจากคลาส'),
                        content: Text('ต้องการออกจาก "${c.name}" ใช่หรือไม่?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('ยกเลิก'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('ออกจากคลาส'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await ClassService.leaveClassroom(c.classId!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ออกจากคลาสสำเร็จ')),
                          );
                          onRefresh?.call();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('ออกจากคลาสไม่สำเร็จ: $e')),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (_) => isTeacher
                    ? const [
                        PopupMenuItem(value: 'edit', child: Text('แก้ไขคลาส')),
                        PopupMenuItem(value: 'delete', child: Text('ลบคลาส')),
                      ]
                    : const [
                        PopupMenuItem(
                          value: 'leave',
                          child: Text('ออกจากคลาส'),
                        ),
                      ],
              ),
            ),

            // 🔹 ส่วนเนื้อหาเดิมทั้งหมด
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name ?? '(ไม่มีชื่อคลาส)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.teacher?.username ?? c.teacher?.email ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
