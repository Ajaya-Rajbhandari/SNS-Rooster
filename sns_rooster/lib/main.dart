import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/screens/splash/splash_screen.dart';
import 'package:sns_rooster/screens/login/login_screen.dart';
import 'package:sns_rooster/screens/timesheet/timesheet_screen.dart';
import 'package:sns_rooster/screens/attendance/attendance_screen.dart';
import 'package:sns_rooster/screens/profile/profile_screen.dart';
import 'package:sns_rooster/screens/employee/employee_dashboard_screen.dart';
import 'package:sns_rooster/screens/employee/leave_request_screen.dart';
import 'package:sns_rooster/screens/employee/notification_screen.dart';
import 'package:sns_rooster/screens/admin/admin_dashboard_screen.dart';
import 'package:sns_rooster/screens/admin/user_management_screen.dart';
import 'package:sns_rooster/screens/admin/attendance_management_screen.dart';
import 'package:sns_rooster/screens/admin/admin_timesheet_screen.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:sns_rooster/providers/attendance_provider.dart';
import 'package:sns_rooster/providers/profile_provider.dart';
import 'package:sns_rooster/providers/leave_request_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, AttendanceProvider>(
          create: (context) => AttendanceProvider(context.read<AuthProvider>()),
          update: (context, auth, attendance) => AttendanceProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (context) => ProfileProvider(context.read<AuthProvider>()),
          update: (context, auth, profile) => ProfileProvider(auth),
        ),
        ChangeNotifierProvider(create: (_) => LeaveRequestProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return MaterialApp(
          title: 'SNS Rooster',
          theme: ThemeData(
            fontFamily:
                'Product Sans', // Using Product Sans as the primary font
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
            colorScheme: ColorScheme(
              primary: const Color(0xFF0066CC), // Brighter Primary Blue
              onPrimary: Colors.white,
              primaryContainer: const Color(0xFF004C99), // Brighter Soft Navy
              onPrimaryContainer: Colors.white,
              secondary: const Color(0xFFFFD700), // Brighter Gold/Yellow
              onSecondary: Colors.black,
              secondaryContainer:
                  const Color(0xFFFF8534), // Brighter Soft Orange
              onSecondaryContainer: Colors.black,
              tertiary: const Color(0xFF00D4F5), // Brighter Cyan
              onTertiary: Colors.black,
              error: const Color(0xFFFF1A1A), // Brighter Red
              onError: Colors.white,
              background: const Color(0xFFFFFFFF), // Pure White
              onBackground: const Color(0xFF000000), // Pure Black
              surface: const Color(0xFFFFFFFF), // Pure White
              onSurface: const Color(0xFF000000), // Pure Black
              surfaceVariant: const Color(0xFFE8E8E8), // Brighter Light Gray
              onSurfaceVariant: const Color(0xFF000000), // Pure Black
              outline: const Color(0xFFCCCCCC), // Brighter Border Color
              shadow: Colors.black.withOpacity(0.15), // Lighter Shadow
              inverseSurface: const Color(0xFF000000), // Pure Black
              onInverseSurface: Colors.white,
              inversePrimary:
                  const Color(0xFF99CCFF), // Brighter Inverse Primary
              surfaceTint: const Color(0xFF0066CC), // Brighter Primary Blue
              brightness: Brightness.light,
            ),
          ),
          initialRoute: '/', // Always start with splash screen
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/employee_dashboard': (context) => const EmployeeDashboardScreen(),
            '/admin_dashboard': (context) => const AdminDashboardScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/attendance': (context) => const AttendanceScreen(),
            '/timesheet': (context) => const TimesheetScreen(),
            '/leave_request': (context) => const LeaveRequestScreen(),
            '/notifications': (context) => const NotificationScreen(),
            '/user_management': (context) => const UserManagementScreen(),
            '/attendance_management': (context) =>
                const AttendanceManagementScreen(),
            '/admin_timesheet': (context) => const AdminTimesheetScreen(),
          },
        );
      },
    );
  }
}
