import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/classwork_simple_service.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final String classId;

  const CreateAssignmentScreen({super.key, required this.classId});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _maxScoreController = TextEditingController(text: '100');
  DateTime? _dueDate;

  bool _submitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกวันกำหนดส่ง')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ClassworkSimpleService.createAssignment(
        classId: widget.classId,
        title: _titleController.text.trim(),
        maxScore: int.tryParse(_maxScoreController.text) ?? 100,
        dueDate: _dueDate!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('สร้างงานสำเร็จ')));
      Navigator.pop(context, true); // ✅ ส่ง true กลับไปรีเฟรชหน้าก่อนหน้า
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );
    if (time == null) return;

    setState(() {
      _dueDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('สร้างงานใหม่')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'ชื่องาน',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'กรุณากรอกชื่องาน' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxScoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'คะแนนเต็ม',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('กำหนดส่ง'),
                subtitle: Text(
                  _dueDate == null ? 'ยังไม่ได้เลือก' : df.format(_dueDate!),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDueDate,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: const Icon(Icons.save),
                label: Text(_submitting ? 'กำลังบันทึก...' : 'บันทึกงาน'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
