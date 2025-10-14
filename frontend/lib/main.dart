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
import 'screens/profile_screen.dart';
import 'models/users.dart';
import 'screens/notifications_page.dart';
import 'screens/classwork_page.dart';
import 'screens/people_page.dart';
import 'screens/report_page.dart';
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
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          selectionHandleColor: Colors.blue, // สีจุดจับ
          selectionColor: Colors.blue.shade200, // สีพื้นหลังตอนเลือกข้อความ
          cursorColor: Color.fromARGB(209, 35, 35, 35), // สีเคอร์เซอร์
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color.fromARGB(212, 134, 134, 134), // สีกรอบเวลาพิมพ์
              width: 2,
            ),
          ),
          floatingLabelStyle: const TextStyle(
            color: Color.fromARGB(255, 134, 134, 134), // สี label ตอนโฟกัส
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
        '/profile': (context) => ProfilePage(
              user: ModalRoute.of(context)!.settings.arguments as User,
            ),
        '/notifications': (context) => const NotificationsPage(),
        
        '/people': (context) => const PeoplePage(),
        '/report': (context) => const ReportPage(),
      },
    );
  }
}
