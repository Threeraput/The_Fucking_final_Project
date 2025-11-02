import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final int _otpLength = 6;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late List<TextEditingController> _otpControllers;
  String? _message;
  bool _isLoading = false;

  Color? _messageColor; 

  @override
  void initState() {
    super.initState();
    _otpControllers =
        List.generate(_otpLength, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (var c in _otpControllers) {
      c.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _otp => _otpControllers.map((e) => e.text).join();

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    if (_otpControllers.any((c) => c.text.isEmpty)) {
      setState(() {
        _message = 'Please enter the 6-digit OTP.';
        _isLoading = false;
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _message = 'Passwords do not match.';
        _isLoading = false;

      });
      return;
    }

    try {
      await AuthService.resetPassword(
        widget.email,
        _otp,
        _newPasswordController.text,
      );

      setState(() {
        _message =
            'Password reset successfully! You can now login with your new password.';
        _messageColor = Colors.green; // สีข้อความสำเร็จ
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset! Redirecting to login...')),
      );

      await Future.delayed(const Duration(seconds: 2));
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      setState(() {
        _message = e.toString().replaceFirst('Exception: ', '');
        _messageColor = Colors.red; // สีข้อความผิดพลาด
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(_otpLength, (index) {
        return SizedBox(
          width: 48,
          child: TextField(
            controller: _otpControllers[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
             fontSize: 20,
             fontWeight: FontWeight.bold,
            ),
            maxLength: 1,
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
               focusedBorder: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                  color: Color.fromARGB(230, 20, 99, 247),
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < _otpLength - 1) {
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
              }
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Enter the OTP sent to ${widget.email} and your new password.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // 🔹 กล่องกรอก OTP แบบช่อง ๆ
              _buildOtpFields(),

              const SizedBox(height: 20),
              TextField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blue),
                  )
                  : ElevatedButton(
                      onPressed: _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        style: TextStyle(color: Colors.white),
                        'Reset Password'),
                    ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _message!,
                    style: TextStyle(color: _messageColor),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
