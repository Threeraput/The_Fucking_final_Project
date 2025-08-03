// lib/screens/otp_verification_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/users.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email; // อีเมลหรือ username ที่ใช้ลงทะเบียน

  const OtpVerificationScreen({super.key, required this.email});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  String? _message;
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // ไม่ต้องรับค่า User กลับมาแล้ว เพราะ AuthService.verifyOtp คืน bool
      await AuthService.verifyOtp(widget.email, _otpController.text);

      // --- เพิ่มโค้ดส่วนนี้กลับเข้าไปใหม่ครับ ---
      setState(() {
        _message = 'OTP verified successfully! Your account is now active.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verified! Redirecting to login...')),
      );
      await Future.delayed(Duration(seconds: 2));
      Navigator.of(
        context,
      ).pushReplacementNamed('/login'); // <-- ฟังก์ชันนำทางกลับไปหน้า Login
      // ----------------------------------------
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

  Future<void> _requestNewOtp() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      await AuthService.requestOtp(
        widget.email,
      ); // ตรงนี้ยังใช้ identifier ได้ตามเดิม
      setState(() {
        _message = 'New OTP sent to ${widget.email}.';
      });
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
      appBar: AppBar(title: Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'A 6-digit OTP has been sent to ${widget.email}. Please enter it below to verify your account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: 'Enter OTP',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyOtp,
                    child: Text('Verify OTP'),
                  ),
            SizedBox(height: 10),
            TextButton(
              onPressed: _isLoading ? null : _requestNewOtp,
              child: Text('Didn\'t receive OTP? Request new'),
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
