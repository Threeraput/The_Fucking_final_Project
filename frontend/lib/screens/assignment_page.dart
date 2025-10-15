import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key});

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final List<String> _attachedFiles = [];

  void _saveAssignment() {
    if (titleController.text.trim().isEmpty && _attachedFiles.isEmpty) return;
    Navigator.pop(context, {
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'author': 'Instructor', // สามารถเปลี่ยนเป็นชื่อผู้ใช้จริง 
    });
  }

  Future<void> _pickAttachment() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false, // เลือกไฟล์เดียว
      withData: true, // เพื่อให้แสดงผลได้ในทุกแพลตฟอร์ม
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _attachedFiles.add(result.files.single.name);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📎 Attached: ${result.files.single.name}')),
      );
    } else {
      debugPrint('❌ User canceled the picker');
    }
  } catch (e) {
    debugPrint('⚠️ File picking failed: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error picking file: $e')),
    );
  }
}

  void _removeAttachment(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Assignment'),
        actions: [
          TextButton(
            onPressed: _saveAssignment,
            style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            child: const Text(
              'Assign',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: titleController,
              maxLines: null,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                ),
                filled: true,
                fillColor: const Color.fromARGB(255, 255, 249, 249),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                alignLabelWithHint: true,
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                ),
                filled: true,
                fillColor: const Color.fromARGB(255, 255, 249, 249),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
           Row(
              children: [
                IconButton(
                  onPressed: _pickAttachment,
                  icon: const Icon(Icons.attach_file, color: Colors.blueAccent),
                ),
                const Text(
                  "Add attachment",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),

            // แสดงไฟล์ที่แนบมา
            if (_attachedFiles.isNotEmpty) ...[
              const SizedBox(height: 10),
              ..._attachedFiles.asMap().entries.map((entry) {
                int index = entry.key;
                String fileName = entry.value;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          fileName,
                          style: const TextStyle(
                              fontSize: 15, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                        onPressed: () => _removeAttachment(index),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );      
  }
}
