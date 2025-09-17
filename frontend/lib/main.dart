// lib/main.dart
import 'package:flutter/material.dart';
import 'package:frontend/screens/admin_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/otp_verification_screen.dart'; 
import 'screens/forgot_password_screen.dart'; 
import 'screens/reset_password_screen.dart'; 
import 'services/auth_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final accessToken = await AuthService.getAccessToken();
  runApp(MyApp(initialRoute: accessToken != null ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Attendance App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        // แก้ไข Routes สำหรับ OtpVerificationScreen
        '/verify-otp': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String?;
          if (args == null) {
          // กรณีไม่มี email ส่งมา ให้กลับไปหน้า login หรือแสดง error
            return LoginScreen(); // หรือ ErrorScreen()
          }
          // *** แก้ไขตรงนี้: เปลี่ยน identifier เป็น email ***
          return OtpVerificationScreen(email: args);
        },
        '/forgot-password': (context) => ForgotPasswordScreen(),
        '/reset-password': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String?;
          if (args == null) {
            // กรณีไม่มี email ส่งมา ให้กลับไปหน้า forgot password
            return ForgotPasswordScreen(); // หรือ ErrorScreen()
          }
          return ResetPasswordScreen(email: args);
        },
        '/admin-dashboard': (context) => AdminDashboardScreen(),
      },
    );
  }
}
