import 'package:flutter/material.dart';
import 'package:frontend/models/users.dart';
import '../services/auth_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getCurrentUserFromLocal();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.of(context).pushReplacementNamed('/login'); // กลับไปหน้า Login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_currentUser == null)
              Text('Loading user data...')
            else ...[
              Text(
                'Welcome, ${_currentUser!.firstName ?? _currentUser!.username}!',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 10),
              Text('Username: ${_currentUser!.username}'),
              if (_currentUser!.email != null)
                Text('Email: ${_currentUser!.email}'),
              if (_currentUser!.studentId != null)
                Text('Student ID: ${_currentUser!.studentId}'),
              if (_currentUser!.teacherId != null)
                Text('Teacher ID: ${_currentUser!.teacherId}'),
              Text('Roles: ${_currentUser!.roles.join(', ')}'),
              SizedBox(height: 30),
            ],
            ElevatedButton(onPressed: _logout, child: Text('Logout')),
          ],
        ),
      ),
    );
  }
}
