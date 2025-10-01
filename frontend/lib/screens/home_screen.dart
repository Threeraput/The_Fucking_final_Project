import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/users.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  bool _isAdmin = false;

  // ตัวอย่างข้อมูลคอร์ส/ห้องเรียน
  List<Map<String, String>> _courses = [
    {
      'title': 'Math 101',
      'icon': 'M',
      'desc': 'Basic Math',
      'location': 'Room 101',
    },
    {
      'title': 'Computer Science',
      'icon': 'C',
      'desc': 'Intro to CS',
      'location': 'Lab 1',
    },
    {
      'title': 'English Literature',
      'icon': 'E',
      'desc': 'Poems & Stories',
      'location': 'Room 202',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getCurrentUserFromLocal();
    setState(() {
      _currentUser = user;
      _isAdmin = user?.roles.contains('admin') ?? false;
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('You have 3 new notifications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _addCourseDialog() {
    final _titleController = TextEditingController();
    final _descController = TextEditingController();
    final _locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add New Course'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Course Name'),
              ),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _courses.add({
                  'title': _titleController.text,
                  'icon': _titleController.text.isNotEmpty
                      ? _titleController.text[0].toUpperCase()
                      : '?',
                  'desc': _descController.text,
                  'location': _locationController.text,
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          if (_isAdmin)
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin-dashboard');
              },
              child: Text('Admin', style: TextStyle(color: Colors.cyanAccent)),
            ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),

      // Drawer สำหรับ Hamburger Menu
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Notification
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                onTap: _showNotifications,
              ),
              const Divider(),
              // ห้องเรียน / Courses List
              Expanded(
                child: ListView.builder(
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Text(
                          course['icon'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(course['title'] ?? ''),
                      subtitle: Text(course['desc'] ?? ''),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/course-detail',
                          arguments: course,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // User Info แบบกล่อง
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${_currentUser!.firstName ?? _currentUser!.username} 👋',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Roles: ${_currentUser!.roles.join(', ')}'),
                      ],
                    ),
                  ),

                  // Courses List ด้านล่าง
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _courses.length,
                      itemBuilder: (context, index) {
                        final course = _courses[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              course['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${course['desc'] ?? ''}\nLocation: ${course['location'] ?? ''}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/course-detail',
                                arguments: course,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

      // ปุ่มบวกเพิ่มห้องเรียน
      floatingActionButton: FloatingActionButton(
        onPressed: _addCourseDialog,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
