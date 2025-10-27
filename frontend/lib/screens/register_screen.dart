import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/users.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

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

  String? _selectedRole;
  String? _message;
  bool _isLoading = false;

  final List<String> _roles = ['student', 'teacher'];

  // สำหรับจัดการ error ข้อความแดง
  String? _usernameError;
  String? _passwordError;
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _selectedRole = _roles.first;

    _usernameController.addListener(() {
      if (_usernameError != null) setState(() => _usernameError = null);
    });
    _passwordController.addListener(() {
      if (_passwordError != null) setState(() => _passwordError = null);
    });
    _firstNameController.addListener(() {
      if (_firstNameError != null) setState(() => _firstNameError = null);
    });
    _lastNameController.addListener(() {
      if (_lastNameError != null) setState(() => _lastNameError = null);
    });
    _emailController.addListener(() {
      if (_emailError != null) setState(() => _emailError = null);
    });
  }

  Future<void> _register() async {
    bool isValid = true;

    if (_usernameController.text.isEmpty) {
      setState(() => _usernameError = 'Enter your username');
      isValid = false;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Enter your password');
      isValid = false;
    }
    if (_firstNameController.text.isEmpty) {
      setState(() => _firstNameError = 'Enter your FirstName');
      isValid = false;
    }
    if (_lastNameController.text.isEmpty) {
      setState(() => _lastNameError = 'Enter your LastName');
      isValid = false;
    }
    if (_emailController.text.isEmpty) {
      setState(() => _emailError = 'Enter your Email');
      isValid = false;
    }
    if (_selectedRole == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter your Role')));
      isValid = false;
    }

    if (!isValid) return;

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
      'role': _selectedRole,
    };

    try {
      User newUser = await AuthService.register(userData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your account has been created! Check your email to activate it.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                errorText: _usernameError,
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: Colors.blueAccent,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: _passwordError,
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Colors.blueAccent,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                errorText: _firstNameError,
                prefixIcon: const Icon(
                  Icons.badge_outlined,
                  color: Colors.blueAccent,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                errorText: _lastNameError,
                prefixIcon: const Icon(
                  Icons.badge_outlined,
                  color: Colors.blueAccent,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _emailError,
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Colors.blueAccent,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField2<String>(
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              hint: const Text(
                'Select Your Role',
                style: TextStyle(fontSize: 14),
              ),

              items: _roles.map((role) {
                IconData roleIcon;
                switch (role) {
                  case 'student':
                    roleIcon = Icons.person_outline;
                    break;
                  case 'teacher':
                    roleIcon = Icons.school_outlined;
                    break;
                  default:
                    roleIcon = Icons.group;
                }
                return DropdownMenuItem<String>(
                  value: role,
                  child: Row(
                    children: [
                      Icon(roleIcon, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(role, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedRole = value!);
              },
              validator: (value) =>
                  value == null ? 'Please select your Role.' : null,
              dropdownStyleData: DropdownStyleData(
                maxHeight: 300,
                width: 380,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blueAccent,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color.fromARGB(185, 64, 195, 255),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _message!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/login');
              },
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(Colors.black),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
              ),
              child: const Text('Already have an account? Login here'),
            ),
          ],
        ),
      ),
    );
  }
}
