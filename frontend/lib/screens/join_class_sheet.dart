import 'package:flutter/material.dart';
import 'package:frontend/services/class_service.dart';

class JoinClassSheet extends StatefulWidget {
  const JoinClassSheet({super.key});

  @override
  State<JoinClassSheet> createState() => _JoinClassSheetState();
}

class _JoinClassSheetState extends State<JoinClassSheet> {
  final _codeCtl = TextEditingController();
  bool _loading = false;
  String? _errorText; // ✅ เก็บข้อความ error ใต้กล่องข้อความ

  Future<void> _join() async {
    final code = _codeCtl.text.trim();
    if (code.isEmpty) {
      setState(() => _errorText = 'กรุณากรอกรหัสห้องเรียน');
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      await ClassService.joinClassroom(code);

      if (!mounted) return;
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เข้าร่วมคลาสสำเร็จ')));
    } catch (e) {
      if (!mounted) return;

      String msg = e.toString();

      if (msg.contains('not found') ||
          msg.contains('ไม่พบ') ||
          msg.contains('Invalid') ||
          msg.contains('invalid')) {
        msg = 'รหัสห้องเรียนไม่ถูกต้อง';
      } else if (msg.contains('already') ||
          msg.contains('Already') ||
          msg.contains('joined') ||
          msg.contains('exists')) {
        msg = 'คุณได้เข้าร่วมคลาสนี้แล้ว';
      } else if (msg.contains('403')) {
        msg = 'บัญชีนี้ไม่มีสิทธิ์เข้าคลาส';
      } else {
        msg = 'เกิดข้อผิดพลาดในการเข้าร่วมคลาส';
      }

      // ✅ แสดงข้อความในกล่องข้อความ
      setState(() => _errorText = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _codeCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'เข้าร่วมคลาสด้วยรหัส',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeCtl,
            decoration: InputDecoration(
              labelText: 'รหัสคลาส',
              border: const OutlineInputBorder(),
              errorText: _errorText, // ✅ แสดง error ใต้กล่อง
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.group_add),
              label: Text(_loading ? 'กำลังเข้าร่วม...' : 'เข้าร่วมคลาส'),
              onPressed: _loading ? null : _join,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
