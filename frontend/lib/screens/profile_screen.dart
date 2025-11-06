import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/users.dart';
import 'package:frontend/services/user_service.dart';
import 'package:frontend/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _me;
  bool _loading = true;
  bool _saving = false;

  final _usernameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _teacherIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    setState(() {
      _loading = true;
    });
    try {
      // โหลดข้อมูลล่าสุดจากเซิร์ฟเวอร์ (เพื่อได้ avatarUrl ปัจจุบัน)
      final fresh = await UserService.fetchMe();
      _me = fresh;
      _usernameCtrl.text = fresh.username;
      _firstNameCtrl.text = fresh.firstName ?? '';
      _lastNameCtrl.text = fresh.lastName ?? '';
      _studentIdCtrl.text = fresh.studentId ?? '';
      _teacherIdCtrl.text = fresh.teacherId ?? '';
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('โหลดโปรไฟล์ไม่สำเร็จ: $e')));
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_me == null) return;
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (res == null || res.files.isEmpty) return;

      final path = res.files.single.path;
      if (path == null) return;

      setState(() => _saving = true);

      // อัปโหลดรูป
      final updatedUser = await UserService.uploadAvatar(File(path));

      setState(() {
        _me = updatedUser;
        _saving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปโหลดรูปโปรไฟล์สำเร็จ')),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('อัปโหลดรูปไม่สำเร็จ: $e')));
      }
    }
  }

  Future<void> _deleteAvatar() async {
    if (_me == null) return;
    try {
      setState(() => _saving = true);
      final updatedUser = await UserService.deleteAvatar();
      setState(() {
        _me = updatedUser;
        _saving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ลบรูปโปรไฟล์สำเร็จ')));
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ลบรูปไม่สำเร็จ: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_me == null) return;
    try {
      setState(() => _saving = true);
      final updated = await UserService.updateUser(
        userId: _me!.userId,
        username: _usernameCtrl.text,
        firstName: _firstNameCtrl.text,
        lastName: _lastNameCtrl.text,
        studentId: _studentIdCtrl.text,
        teacherId: _teacherIdCtrl.text,
      );
      setState(() {
        _me = updated;
        _saving = false;
      });

      // อัปเดต local cache ถ้าคุณมีเมธอดให้เก็บ (อาจไม่มีในโปรเจ็กต์)
      // await AuthService.setCurrentUserToLocal(updated);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกโปรไฟล์สำเร็จ')));
        Navigator.pop(context, true); // ส่ง true กลับเพื่อให้หน้าก่อนรีเฟรช
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;

    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์ของฉัน'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('บันทึก'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : me == null
          ? const Center(child: Text('ไม่พบข้อมูลผู้ใช้'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar
                  Builder(
                    builder: (context) {
                      final imgUrl = UserService.absoluteAvatarUrl(
                        me.avatarUrl,
                      );
                      return Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.blueGrey.shade100,
                            backgroundImage: imgUrl != null
                                ? NetworkImage(imgUrl)
                                : null,
                            child: imgUrl == null
                                ? Text(
                                    me.username.isNotEmpty
                                        ? me.username[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _saving
                                    ? null
                                    : _pickAndUploadAvatar,
                                icon: const Icon(Icons.photo),
                                label: const Text('เปลี่ยนรูป'),
                              ),
                              const SizedBox(width: 8),
                              if (me.avatarUrl != null &&
                                  me.avatarUrl!.isNotEmpty)
                                TextButton.icon(
                                  onPressed: _saving ? null : _deleteAvatar,
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'ลบรูป',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Email (read-only)
                  TextFormField(
                    initialValue: me.email ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'อีเมล (แก้ไขไม่ได้)',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อผู้ใช้',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _firstNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อจริง',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lastNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'นามสกุล',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _studentIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'รหัสนักเรียน',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _teacherIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'รหัสอาจารย์',
                      prefixIcon: Icon(Icons.co_present_outlined),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
