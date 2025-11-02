// lib/screens/teacher_open_checkin_sheet.dart
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
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
  final _radiusCtl = TextEditingController(text: '100');
  final _formKey = GlobalKey<FormState>();
  bool _posting = false;

  @override
  void dispose() {
    _minCtl.dispose();
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

  Future<void> _open() async {
    if (!_formKey.currentState!.validate()) return;

    final minutes = int.parse(_minCtl.text.trim());
    final radius = int.parse(_radiusCtl.text.trim());

    setState(() => _posting = true);
    try {
      // 1) อ่าน GPS ก่อน เพื่อส่งไปกับ openSession (backend ต้องการ)
      final pos = await LocationHelper.getCurrentPositionOrThrow();

      // 2) เปิด session พร้อม latitude/longitude
      await AttendanceService.openSession(
        classId: widget.classId,
        expiresInMinutes: minutes,
        radiusMeters: radius,
        latitude: pos.latitude, // 👈 ใหม่
        longitude: pos.longitude, // 👈 ใหม่
      );

      // 3) ไม่ต้องเรียก updateTeacherAnchor แล้ว (ลบทิ้ง)
      // await AttendanceService.updateTeacherAnchor(...);  // ❌ ลบ

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ประกาศเช็คชื่อสำเร็จ')));
    } catch (e) {
      if (!mounted) return;
      print('🧩 [TeacherOpenCheckinSheet] error: $e'); // ไว้debugต่อ
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
            TextFormField(
              readOnly: true,
              controller: _minCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'หมดอายุใน (นาที)',
                border: OutlineInputBorder(),
                helperText: 'เช่น 15 นาที',
                suffixIcon: Icon(Icons.timer_outlined),
              ),
              onTap: () async {
              int currentValue = int.tryParse(_minCtl.text) ?? 15;
              int tempValue = currentValue;

await showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (context) {
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('เลือกเวลาหมดอายุ (นาที)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: NumberPicker(
                  value: tempValue,
                  minValue: 1,
                  maxValue: 240,
                  onChanged: (val) => setModalState(() => tempValue = val),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      style: TextStyle(color: Colors.grey),
                      'ยกเลิก'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    onPressed: () {
                      setState(() => _minCtl.text = tempValue.toString());
                      Navigator.pop(context);
                    },
                    child: const Text('ตกลง'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  },
);


              },
              validator: (v) => _requiredInt(v, min: 1, max: 240),
            ),
            
            const SizedBox(height: 12),
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
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: _posting ? null : _open,
              icon: const Icon(Icons.play_circle_outline),
              label: _posting
                  ? const Text('กำลังเปิด...')
                  : const Text('เริ่มเช็คชื่อ'),
              
            ),
          ],
        ),
      ),
    );
  }
}
