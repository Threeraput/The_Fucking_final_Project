import 'package:flutter/material.dart';

class CourseDetailPage extends StatelessWidget {
  final Map<String, String> course;

  const CourseDetailPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course['title'] ?? 'Course Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course['title'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Description: ${course['desc'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Location: ${course['location'] ?? ''}'),
          ],
        ),
      ),
    );
  }
}
