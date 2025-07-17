import 'package:flutter/material.dart';
import '../services/auth_service.dart';
 // import User model if needed for response

class RegisterScreen extends StatefulWidget { 
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _teacherIdController = TextEditingController();

  String? _message;
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final userData = {
      'username': _usernameController.text,
      'password': _passwordController.text,
      'first_name': _firstNameController.text.isNotEmpty
          ? _firstNameController.text
          : null,
      'last_name': _lastNameController.text.isNotEmpty
          ? _lastNameController.text
          : null,
      'email': _emailController.text.isNotEmpty ? _emailController.text : null,
      'student_id': _studentIdController.text.isNotEmpty
          ? _studentIdController.text
          : null,
      'teacher_id': _teacherIdController.text.isNotEmpty
          ? _teacherIdController.text
          : null,
    };

    try {
      await AuthService.register(userData);
      setState(() {
        _message = 'Registration successful! You can now log in.';
        _usernameController.clear();
        _passwordController.clear();
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _studentIdController.clear();
        _teacherIdController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration successful! Redirecting to login...'),
        ),
      );
      await Future.delayed(Duration(seconds: 2));
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      setState(() {
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'First Name (Optional)'),
              ),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name (Optional)'),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email (Optional)'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _studentIdController,
                decoration: InputDecoration(labelText: 'Student ID (Optional)'),
              ),
              TextField(
                controller: _teacherIdController,
                decoration: InputDecoration(labelText: 'Teacher ID (Optional)'),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      child: Text('Register'),
                    ),
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
