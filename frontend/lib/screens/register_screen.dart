// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
//import 'dart:convert';
//import 'dart:math'; // เพิ่ม import นี้
import '../services/auth_service.dart';
import '../models/users.dart'; // *** ตรวจสอบให้แน่ใจว่า import นี้มีอยู่และถูกต้อง ***

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _teacherIdController = TextEditingController();

  // เพิ่มตัวแปรสำหรับเก็บ role ที่เลือก
  String? _selectedRole;
  String? _message;
  bool _isLoading = false;

  // รายการ role ที่มีให้เลือก
  final List<String> _roles = ['student', 'teacher'];

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('กรุณาเลือกบทบาท')));
        return;
      }

      setState(() {
        _isLoading = true;
        _message = null;
      });

      final userData = {
        'username': _usernameController.text,
        'password': _passwordController.text,
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'role': _selectedRole, // ส่ง role ไปให้ Backend
        
      };

      // ลบโค้ดนี้ออกถ้าคุณต้องการให้ Backend เป็นคน generate ID
      // 'student_id': _selectedRole == 'student' ? _generatedId : null,
      // 'teacher_id': _selectedRole == 'teacher' ? _generatedId : null,
      // ถ้าคุณไม่ต้องการให้ Frontend ส่ง student_id หรือ teacher_id ไปเอง ให้ลบ field เหล่านี้ออก

      try {
        User newUser = await AuthService.register(userData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'สมัครสมาชิกสำเร็จ! โปรดตรวจสอบอีเมลเพื่อยืนยันบัญชี',
            ),
          ),
        );
        Navigator.of(
          context,
        ).pushReplacementNamed('/verify-otp', arguments: newUser.email);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedRole = _roles.first; // ตั้งค่าเริ่มต้นเมื่อหน้าจอโหลด
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('สมัครสมาชิก')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'ชื่อผู้ใช้'),
                validator: (value) =>
                    value!.isEmpty ? 'โปรดระบุชื่อผู้ใช้' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'รหัสผ่าน'),
                obscureText: true,
                validator: (value) =>
                    value!.isEmpty ? 'โปรดระบุรหัสผ่าน' : null,
              ),
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'ชื่อจริง'),
                validator: (value) =>
                    value!.isEmpty ? 'โปรดระบุชื่อจริง' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'นามสกุล'),
                validator: (value) =>
                    value!.isEmpty ? 'โปรดระบุชื่อนามสกุล' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'อีเมล'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'โปรดระบุอีเมล' : null,
              ),
              SizedBox(height: 16),
              // Dropdown สำหรับเลือก Role
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(labelText: 'เลือกบทบาท'),
                items: _roles.map<DropdownMenuItem<String>>((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                  }
                },
                validator: (value) => value == null ? 'โปรดเลือกบทบาท' : null,
              ),
              SizedBox(height: 16),
              // ลบโค้ดส่วนนี้ออกถ้าต้องการให้ Backend เป็นคน Generate ID
              // แสดง Generated ID
              // if (_generatedId != null)
              //   Text(
              //     'Generated ID: $_generatedId',
              //     style: TextStyle(fontWeight: FontWeight.bold),
              //   ),
              // SizedBox(height: 16),
              // และลบ TextField สำหรับ student_id และ teacher_id ออก
              ElevatedButton(onPressed: _register, child: Text('สมัครสมาชิก')),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_message!, style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/login');
                },
                child: Text('Already have an account? Login here'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
