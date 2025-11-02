import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _titleCtl.dispose();
    _bodyCtl.dispose();
    super.dispose();
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
      // TODO: เรียก Service จริง เช่น AnnouncementService.create(...)
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('สร้างประกาศสำเร็จ')));
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
    return Scaffold(
      appBar: AppBar(title: Text('ประกาศ • ${widget.className}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtl,
            maxLines: 1,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.article_outlined),
              labelText: 'หัวข้อ',
               border: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtl,
            maxLines: null,
            decoration: InputDecoration(
              labelText: 'รายละเอียด',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
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
