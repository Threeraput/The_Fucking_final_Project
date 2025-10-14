import 'package:flutter/material.dart';

class CreateClassPage extends StatefulWidget {
  const CreateClassPage({super.key});

  @override
  State<CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<CreateClassPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _classCodeController = TextEditingController();

  void _createClass() {
    if (_formKey.currentState!.validate()) {
      String className = _classNameController.text;
      String classCode = _classCodeController.text;

      final newClass = {
        'title': className,
        'icon': className.isNotEmpty ? className[0].toUpperCase() : '?',
        'desc': 'รหัสห้อง: $classCode',
        'location': '',
      };

      Navigator.pop(context, newClass);
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _classCodeController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('สร้างห้องเรียน')),
    body: LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _classNameController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.class_outlined),
                              labelText: 'Class Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please Enter Class Name'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _classCodeController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.description_outlined),
                              labelText: 'Details',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _createClass,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: Colors.blueAccent,
                            ),
                            child: const Text(
                              'Create Class',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
}
