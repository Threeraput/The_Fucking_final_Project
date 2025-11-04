import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/announcement_service.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final String classId;
  final String className;

  const CreateAnnouncementScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _titleCtl = TextEditingController();
  final _bodyCtl = TextEditingController();
  bool _posting = false;

  // เพิ่มตัวเลือกเสริม
  bool _pinned = false;
  bool _visible = true;
  DateTime? _expiresAt;

  @override
  void dispose() {
    _titleCtl.dispose();
    _bodyCtl.dispose();
    super.dispose();
  }

  Future<void> _pickExpireDateTime() async {
    final now = DateTime.now();
    final init = _expiresAt ?? now.add(const Duration(days: 7));

    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
    );
    if (t == null) return;

    setState(() {
      _expiresAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _post() async {
    final title = _titleCtl.text.trim();
    final body = _bodyCtl.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรอกหัวข้อประกาศ')));
      return;
    }

    setState(() => _posting = true);
    try {
      await AnnouncementService.create(
        classId: widget.classId,
        title: title,
        body: body.isEmpty ? null : body,
        pinned: _pinned,
        visible: _visible,
        expiresAt:
            _expiresAt, // ส่งเป็น DateTime? (ให้ service แปลงเป็น ISO8601)
      );

      if (!mounted) return;
      // ให้หน้าก่อนหน้ารู้ว่าทำสำเร็จแล้วไป refresh เอง
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('สร้างประกาศไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: Text('ประกาศ • ${widget.className}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'หัวข้อ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtl,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'รายละเอียด (ไม่บังคับ)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),

          // แถวตัวเลือก
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: _pinned,
                  onChanged: (v) => setState(() => _pinned = v ?? false),
                  title: const Text('ปักหมุด (Pinned)'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SwitchListTile(
                  value: _visible,
                  onChanged: (v) => setState(() => _visible = v),
                  title: const Text('แสดงให้นักเรียนเห็น'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),

          // วันหมดอายุ (ไม่บังคับ)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('วันหมดอายุ (ไม่บังคับ)'),
            subtitle: Text(
              _expiresAt == null
                  ? '— ไม่ตั้งหมดอายุ —'
                  : df.format(_expiresAt!.toLocal()),
            ),
            trailing: OutlinedButton.icon(
              icon: const Icon(Icons.event),
              label: const Text('ตั้งวัน/เวลา'),
              onPressed: _pickExpireDateTime,
            ),
          ),
          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: _posting ? null : _post,
            icon: const Icon(Icons.campaign),
            label: _posting
                ? const Text('กำลังโพสต์...')
                : const Text('โพสต์ประกาศ'),
          ),
        ],
      ),
    );
  }
}
