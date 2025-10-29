// 🔹 ใช้ร่วมกับ ClassDetailsScreen
// ต้อง import เพิ่ม:
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/screens/teacher_open_checkin_sheet.dart';
import 'package:frontend/screens/student_checkin_screen.dart';
import 'package:frontend/services/attendance_service.dart';

class _ActiveSessionsSection extends StatefulWidget {
  final String classId;
  final bool isTeacher;
  const _ActiveSessionsSection({
    required this.classId,
    required this.isTeacher,
  });

  @override
  State<_ActiveSessionsSection> createState() => _ActiveSessionsSectionState();
}

class _ActiveSessionsSectionState extends State<_ActiveSessionsSection> {
  late Future<List<Map<String, dynamic>>> _futureSessions;

  @override
  void initState() {
    super.initState();
    _futureSessions = _loadSessions();
  }

  Future<List<Map<String, dynamic>>> _loadSessions() async {
    final all = await AttendanceService.getActiveSessions();
    return all
        .where((m) => (m['class_id']?.toString() ?? '') == widget.classId)
        .toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureSessions = _loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureSessions,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'ไม่สามารถโหลด Session ได้: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          if (widget.isTeacher) {
            return Card(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('ยังไม่มีการเปิดเช็คชื่อ')),
                    FilledButton.icon(
                      onPressed: () async {
                        final opened = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) =>
                              TeacherOpenCheckinSheet(classId: widget.classId),
                        );
                        if (opened == true) _refresh();
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('เปิดเช็คชื่อ'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        // ถ้ามี session
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เช็คชื่อที่กำลังเปิดอยู่',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...sessions.map((s) => _buildSessionCard(context, s)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildSessionCard(BuildContext context, Map<String, dynamic> data) {
    final df = DateFormat('HH:mm');
    final expiresAt = DateTime.tryParse(data['expires_at']?.toString() ?? '');
    final expTxt = expiresAt != null
        ? 'หมดอายุ ${df.format(expiresAt.toLocal())}'
        : 'ไม่ทราบเวลา';
    final radius = data['radius_meters']?.toString() ?? '-';
    final lat = data['anchor_lat']?.toString() ?? '-';
    final lon = data['anchor_lon']?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.access_time),
        title: Text('Session กำลังเปิดอยู่'),
        subtitle: Text('$expTxt · รัศมี $radius m\nAnchor: $lat, $lon'),
        trailing: widget.isTeacher
            ? FilledButton(
                onPressed: () async {
                  final opened = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        TeacherOpenCheckinSheet(classId: widget.classId),
                  );
                  if (opened == true) _refresh();
                },
                child: const Text('เปิดใหม่'),
              )
            : FilledButton(
                onPressed: () async {
                  final ok = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StudentCheckinScreen(classId: widget.classId),
                    ),
                  );
                  if (ok == true) _refresh();
                },
                child: const Text('เช็คชื่อ'),
              ),
      ),
    );
  }
}
