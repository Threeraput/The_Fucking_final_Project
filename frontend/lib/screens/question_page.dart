import 'package:flutter/material.dart';

class QuestionPage extends StatelessWidget {
  const QuestionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final questionController = TextEditingController();
    final detailsController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Question'),
        backgroundColor: Colors.teal,
      ),
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Question', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your question',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Details', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: detailsController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Add more context or info',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question posted!')),
          );
          Navigator.pop(context);
        },
        label: const Text('Save'),
        icon: const Icon(Icons.save),
        backgroundColor: Colors.teal,
      ),
    );
  }
}
