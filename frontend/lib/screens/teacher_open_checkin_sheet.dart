// lib/screens/teacher_open_checkin_sheet.dart
import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../utils/location_helper.dart';

class TeacherOpenCheckinSheet extends StatefulWidget {
  final String classId;
  const TeacherOpenCheckinSheet({super.key, required this.classId});

  @override
  State<TeacherOpenCheckinSheet> createState() =>
      _TeacherOpenCheckinSheetState();
}

class _TeacherOpenCheckinSheetState extends State<TeacherOpenCheckinSheet> {
  final _minCtl = TextEditingController(text: '15');
  final _lateCtl = TextEditingController(
    text: '10',
  ); // 👈 เพิ่มช่อง Late Cutoff (นาที)
  final _radiusCtl = TextEditingController(text: '100');
  final _formKey = GlobalKey<FormState>();
  bool _posting = false;

  @override
  void dispose() {
    _minCtl.dispose();
    _lateCtl.dispose(); // 👈 dispose ด้วย
    _radiusCtl.dispose();
    super.dispose();
  }

  String? _requiredInt(String? v, {int min = 1, int max = 1440}) {
    if (v == null || v.trim().isEmpty) return 'กรอกตัวเลข';
    final n = int.tryParse(v.trim());
    if (n == null) return 'ต้องเป็นตัวเลข';
    if (n < min || n > max) return 'ระหว่าง $min–$max';
    return null;
  }

  // ใช้ validator สำหรับ late cutoff ที่ต้องไม่เกิน minutes
  String? _lateCutoffValidator(String? v) {
    final base = _requiredInt(v, min: 1, max: 1440);
    if (base != null) return base;

    final minutes = int.tryParse(_minCtl.text.trim());
    final cutoff = int.tryParse(v!.trim());
    if (minutes != null && cutoff != null && cutoff > minutes) {
      return 'ต้องไม่เกินเวลาหมดอายุ (${minutes} นาที)';
    }
    return null;
  }

  Future<void> _open() async {
    if (!_formKey.currentState!.validate()) return;

    final minutes = int.parse(_minCtl.text.trim()); // เช่น 60
    final cutoff = int.parse(_lateCtl.text.trim()); // เช่น 10
    final radius = int.parse(_radiusCtl.text.trim());

    // กันกรณีที่มีการแก้ไขค่าแล้ว validator ไม่จับทัน
    if (cutoff > minutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เวลาตัดสายต้องไม่เกินเวลาหมดอายุ')),
      );
      return;
    }

    setState(() => _posting = true);
    try {
      final pos = await LocationHelper.getCurrentPositionOrThrow();

      await AttendanceService.openSession(
        classId: widget.classId,
        expiresInMinutes: minutes, // ใช้เวลาหมดอายุรวม
        radiusMeters: radius,
        latitude: pos.latitude,
        longitude: pos.longitude,
        lateCutoffMinutes: cutoff, // 👈 ส่ง cutoff ไปด้วย
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ประกาศเช็คชื่อสำเร็จ')));
    } catch (e) {
      if (!mounted) return;
      // ignore: avoid_print
      print('🧩 [TeacherOpenCheckinSheet] error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'ประกาศเช็คชื่อ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // หมดอายุใน (นาที)
            TextFormField(
              controller: _minCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'หมดอายุใน (นาที)',
                border: OutlineInputBorder(),
                helperText: 'เช่น 15, 30, 60 นาที',
              ),
              validator: (v) => _requiredInt(v, min: 1, max: 240),
            ),
            const SizedBox(height: 12),

            // เวลาตัดสาย (นาทีหลังเริ่ม)
            TextFormField(
              controller: _lateCtl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'เวลาตัดสาย (นาทีหลังเริ่ม)',
                border: const OutlineInputBorder(),
                helperText:
                    'เช่น 10 นาที (ต้องไม่เกินเวลาหมดอายุ ${_minCtl.text} นาที)',
              ),
              validator: _lateCutoffValidator,
            ),
            const SizedBox(height: 12),

            // รัศมี (เมตร)
            TextFormField(
              controller: _radiusCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'รัศมี (เมตร)',
                border: OutlineInputBorder(),
                helperText: 'เช่น 100 เมตร',
              ),
              validator: (v) => _requiredInt(v, min: 10, max: 2000),
            ),

            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _posting ? null : _open,
              icon: const Icon(Icons.play_circle_outline),
              label: _posting
                  ? const Text('กำลังเปิด...')
                  : const Text('เริ่มเช็คชื่อ'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
