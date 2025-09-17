// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/users.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<User> _pendingTeachers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPendingTeachers();
  }

  Future<void> _fetchPendingTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _pendingTeachers = await AuthService.getPendingTeachers();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveTeacher(String userId) async {
    try {
      await AuthService.approveTeacher(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อนุมัติอาจารย์สำเร็จ')),
      );
      _fetchPendingTeachers(); // รีเฟรชรายการ
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _pendingTeachers.isEmpty
                  ? Center(child: Text('ไม่มี Teacher ที่รอการอนุมัติ'))
                  : ListView.builder(
                      itemCount: _pendingTeachers.length,
                      itemBuilder: (context, index) {
                        final user = _pendingTeachers[index];
                        return ListTile(
                          title: Text('${user.firstName} ${user.lastName}'),
                          subtitle: Text('อีเมล: ${user.email}'),
                          trailing: ElevatedButton(
                            onPressed: () => _approveTeacher(user.userId),
                            child: Text('อนุมัติ'),
                          ),
                        );
                      },
                    ),
    );
  }
}