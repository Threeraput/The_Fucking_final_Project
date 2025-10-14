import 'package:flutter/material.dart';
import 'assignment_page.dart';

class ClassworkPage extends StatelessWidget {
  const ClassworkPage({
    super.key,
    required this.assignments,
    this.onNewAssignment,
  });

  final List<Map<String, String>> assignments;
  final void Function(Map<String, String>)? onNewAssignment;

  void _openAssignmentPage(BuildContext context) async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const AssignmentPage()),
    );

    if (result != null && onNewAssignment != null) {
      onNewAssignment!(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment "${result['title']}" created!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: assignments.isEmpty
          ? const Center(child: Text('No assignments yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    leading: const Icon(Icons.assignment_outlined, color: Colors.blue, size: 32),
                    title: Text(
                      assignment['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      assignment['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _openAssignmentPage(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
