
// lib/screens/otp_verification_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';


class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final int _otpLength = 6;
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  String? _message;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _otpLength; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers) ctrl.dispose();
    for (var node in _focusNodes) node.dispose();
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _otp => _controllers.map((e) => e.text).join();

  Future<void> _verifyOtp() async {
  // ตรวจว่ากรอกครบทุกช่องหรือไม่
  if (_controllers.any((c) => c.text.isEmpty)) {
    setState(() {
      _message = 'Please enter the 6-digit OTP.';
    });
    return;
  }

  final otp = _controllers.map((e) => e.text).join();

  setState(() {
    _isLoading = true;
    _message = null;
  });

  try {
    await AuthService.verifyOtp(widget.email, otp);

    setState(() {
      _message = 'OTP verified successfully! Your account is now active.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP verified! Redirecting to login...')),
    );

    await Future.delayed(const Duration(seconds: 2));
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

  Future<void> _requestNewOtp() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await AuthService.requestOtp(widget.email);

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('FaceCheck'),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Verify your Email',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the code sent to your inbox ${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Row ของ 6 TextField
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_otpLength, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 43,
                    height: 52,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      maxLength: 1,
                      showCursor: false, // ซ่อน cursor
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          // ✅ เพิ่มอันนี้
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.black54, // สีกรอบตอนปกติ
                            width: 2,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(230, 20, 99, 247),
                            width: 2,
                          ),
                        ),
                        fillColor: const Color.fromARGB(255, 240, 240, 240),
                      ),
                      onChanged: (value) => _onOtpChanged(value, index),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 30),

              _isLoading
                  ? const CircularProgressIndicator(
                      color: Color.fromARGB(255, 28, 178, 248),
                      strokeWidth: 5,
                    )
                  : ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: const Color.fromARGB(
                          255,
                          28,
                          178,
                          248,
                        ),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Verify',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading ? null : _requestNewOtp,
                style: ButtonStyle(
                  overlayColor: WidgetStateProperty.all(Colors.transparent), // ลบกล่องเวลากด
                ),
                child: const Text(
                  "Didn't receive OTP? Request new",
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),

              if (_message != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _message!,
                    style: const TextStyle(color: Colors.red),
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