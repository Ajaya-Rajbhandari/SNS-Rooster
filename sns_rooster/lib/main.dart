import 'package:flutter/material.dart';
import 'package:sns_rooster/splash_screen.dart';
import 'package:sns_rooster/screens/timesheet/timesheet_screen.dart';
import 'package:sns_rooster/screens/attendance/attendance_screen.dart';
import 'package:sns_rooster/screens/notification/notification_screen.dart';
import 'package:sns_rooster/screens/profile/profile_screen.dart';
import 'package:sns_rooster/screens/employee/employee_dashboard_screen.dart';
import 'package:sns_rooster/screens/admin/admin_dashboard_screen.dart';
import 'package:sns_rooster/screens/leave/leave_request_screen.dart';
// Make sure that LeaveRequestScreen is defined as a class in leave_request_screen.dart and exported properly.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SNS Rooster',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF007BFF), // A shade of blue
          secondary: Color(0xFFFFD700), // A shade of yellow
          surface: Colors.white,
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.black,
          onError: Colors.white,
        ),
        fontFamily: 'Product Sans', // Using Product Sans as the primary font
        // Define text themes for different font weights and styles
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Product Sans',
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Product Sans',
            fontWeight: FontWeight.bold,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Product Sans',
            fontWeight: FontWeight.bold,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'Product Sans',
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Product Sans',
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Product Sans',
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Product Sans',
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Product Sans',
            fontWeight: FontWeight.bold,
          ),
          titleSmall: TextStyle(
            fontFamily: 'Product Sans',
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(fontFamily: 'Product Sans'),
          bodyMedium: TextStyle(fontFamily: 'Product Sans'),
          bodySmall: TextStyle(fontFamily: 'Product Sans'),
          labelLarge: TextStyle(
            fontFamily: 'Product Sans',
            fontWeight: FontWeight.bold,
          ),
          labelMedium: TextStyle(fontFamily: 'Product Sans'),
          labelSmall: TextStyle(fontFamily: 'Product Sans'),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/dashboard': (context) => const EmployeeDashboardScreen(),
        '/leave_request': (context) => const LeaveRequestScreen(),
        // If you still get the error, check the leave_request_screen.dart file for the correct class name and update it here if needed.
        '/leave_request': (context) => const LeaveRequestScreen(),
        '/timesheet': (context) => const TimesheetScreen(),
        '/attendance': (context) => const AttendanceScreen(),
        '/notification': (context) => const NotificationScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
