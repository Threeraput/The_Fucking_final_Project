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
  bool _success = false;

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
      if (mounted) setState(() => _success = false);
    }
  }

   @override
  void initState() {
    super.initState();
    // 🟦 เพิ่ม listener เพื่ออัปเดตตัวอย่างแบบเรียลไทม์
    _titleCtl.addListener(() => setState(() {}));
    _bodyCtl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('ประกาศ • ${widget.className}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🔹 หัวข้อใหญ่
                  Row(
                    children: [
                      const Icon(Icons.campaign_outlined,
                          color: Colors.blueAccent, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'สร้างประกาศใหม่',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 🔹 หัวข้อประกาศ
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

                  // 🔹 รายละเอียดประกาศ
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
                  const SizedBox(height: 20),

                  // 🔹 ปุ่มโพสต์
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _posting ? null : _post,
                    icon: const Icon(Icons.send_rounded),
                    label: _posting
                        ? const Text('กำลังโพสต์...')
                        : const Text(
                            'โพสต์ประกาศ',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),

                  // 🔹 แสดงสถานะการโพสต์
                  if (_posting)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('กำลังโพสต์...',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),

                  if (_success)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: const [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 48),
                          SizedBox(height: 6),
                          Text('โพสต์สำเร็จ!',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green)),
                        ],
                      ),
                    ),

                  // 🔹 Preview ตัวอย่างโพสต์
                   Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Card(
                        color: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.visibility,
                                      color: Colors.blueAccent),
                                  SizedBox(width: 6),
                                  Text(
                                    'ตัวอย่างโพสต์',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _titleCtl.text.isEmpty
                                    ? 'หัวข้อประกาศ'
                                    : _titleCtl.text,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _bodyCtl.text.isEmpty
                                    ? 'รายละเอียด...'
                                    : _bodyCtl.text,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
