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

      // ✅ แสดง SnackBar ทันสมัย
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'อนุมัติอาจารย์สำเร็จ!',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.greenAccent[700],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      _fetchPendingTeachers(); // รีเฟรชรายการ
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'เกิดข้อผิดพลาดในการอนุมัติ',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent[700],
          behavior: SnackBarBehavior.floating,
          // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : RefreshIndicator(
              onRefresh: _fetchPendingTeachers,
              child: _pendingTeachers.isEmpty
                  ? const Center(
                      child: Text(
                        'ไม่มีอาจารย์ที่รอการอนุมัติ',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendingTeachers.length,
                      itemBuilder: (context, index) {
                        final user = _pendingTeachers[index];
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              '${user.firstName} ${user.lastName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text('อีเมล: ${user.email}'),
                            trailing: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              // icon: const Icon(Icons.check, size: 20), // ไอคอนถูกลบออก
                              label: const Text(
                                'Approve',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed: () => _approveTeacher(user.userId),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
    );
  }
}
