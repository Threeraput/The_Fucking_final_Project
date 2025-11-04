// lib/widgets/assignment_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import 'package:frontend/models/classwork.dart';
import 'package:frontend/services/classwork_simple_service.dart';

class AssignmentCard extends StatelessWidget {
  final String classId;
  final Map<String, dynamic> extra;
  final DateTime postedAt;
  final bool isTeacher;
  final VoidCallback? onChanged;

  const AssignmentCard({
    super.key,
    required this.classId,
    required this.extra,
    required this.postedAt,
    required this.isTeacher,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy • HH:mm');
    final title = extra['title']?.toString() ?? 'Assignment';
    final dueIso = extra['due_date']?.toString();
    final due = DateTime.tryParse(dueIso ?? '');
    final maxScore = extra['max_score'];
    final assignmentId = extra['assignment_id']?.toString() ?? '';

    // ฝั่งนักเรียน
    final computedStatus = extra['computed_status']?.toString();
    final my = extra['my_submission'] as Map<String, dynamic>?;
    final graded = my?['graded'] == true;
    final submittedAt = my?['submitted_at'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.assignment_outlined, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'งาน: $title',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  df.format(postedAt.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (due != null)
              Text(
                'กำหนดส่ง: ${df.format(due.toLocal())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (maxScore != null)
              Text(
                'คะแนนเต็ม: $maxScore',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),

            if (isTeacher)
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.list_alt_outlined),
                  label: const Text('ดูการส่งของนักเรียน'),
                  onPressed: () async {
                    try {
                      final rows =
                          await ClassworkSimpleService.listSubmissionsForTeacherTyped(
                            assignmentId,
                          );
                      if (!context.mounted) return;
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) {
                          return SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'รายการส่งงาน',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  for (final r in rows)
                                    ListTile(
                                      leading: Icon(
                                        r.graded
                                            ? Icons.check_circle
                                            : Icons.pending_outlined,
                                      ),
                                      title: Text(r.studentId),
                                      subtitle: Text(
                                        [
                                          'สถานะ: ${latenessToString(r.submissionStatus)}',
                                          if (r.submittedAt != null)
                                            'ส่งเมื่อ: ${DateFormat('d MMM HH:mm').format(r.submittedAt!.toLocal())}',
                                        ].join(' • '),
                                      ),
                                      trailing: r.graded
                                          ? Text('คะแนน ${r.score ?? '-'}')
                                          : null,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('โหลดรายการส่งไม่สำเร็จ: $e')),
                        );
                      }
                    }
                  },
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(() {
                    if (computedStatus != null) return 'สถานะ: $computedStatus';
                    if (submittedAt != null) return 'สถานะ: ส่งแล้ว';
                    return 'สถานะ: ยังไม่ส่ง';
                  }(), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        my == null
                            ? 'ส่ง PDF'
                            : (graded ? 'ดูรายละเอียด' : 'แก้ไขไฟล์/ส่งใหม่'),
                      ),
                      onPressed: () async {
                        try {
                          final picked = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                          );
                          if (picked == null || picked.files.isEmpty) return;
                          final path = picked.files.single.path;
                          if (path == null) return;

                          await ClassworkSimpleService.submitPdf(
                            assignmentId: assignmentId,
                            pdfFile: File(path),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ส่งงานเรียบร้อย')),
                            );
                          }
                          onChanged?.call();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('ส่งงานไม่สำเร็จ: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
