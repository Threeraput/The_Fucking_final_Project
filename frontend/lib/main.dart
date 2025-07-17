import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart'; // เพื่อตรวจสอบสถานะ Login

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final accessToken = await AuthService.getAccessToken();
  runApp(MyApp(initialRoute: accessToken != null ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  MyApp({required this.initialRoute});

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
      },
    );
  }
}
