import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _message;
  bool _isLoading = false;

  Future<void> _requestOtp() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // --- แก้ไขตรงนี้: เปลี่ยนมาเรียก AuthService.requestOtp แทน ---
      await AuthService.requestOtp(_emailController.text);
      // ----------------------------------------------------------------

      setState(() {
        _message =
            'OTP for password reset sent to your email. Please check your inbox.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent! Redirecting to reset password screen...'),
        ),
      );
      await Future.delayed(Duration(seconds: 2));
      // ส่ง email ไปยังหน้า reset password เพื่อให้รู้ว่ากำลังรีเซ็ตของอีเมลไหน
      Navigator.of(context).pushReplacementNamed(
        '/reset-password',
        arguments: _emailController.text,
      );
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
      appBar: AppBar(title: Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter your email address to receive an OTP for password reset.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _requestOtp,
                    child: Text('Request OTP'),
                  ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _message!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
