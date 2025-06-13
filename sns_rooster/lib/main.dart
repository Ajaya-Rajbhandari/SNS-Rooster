import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/screens/splash/splash_screen.dart';
import 'package:sns_rooster/screens/login/login_screen.dart';
import 'package:sns_rooster/screens/timesheet/timesheet_screen.dart';
import 'package:sns_rooster/screens/attendance/attendance_screen.dart';
import 'package:sns_rooster/screens/profile/profile_screen.dart';
import 'package:sns_rooster/screens/employee/employee_dashboard_screen.dart';
import 'package:sns_rooster/screens/leave/leave_request_screen.dart';
import 'package:sns_rooster/screens/notification/notification_screen.dart';
import 'package:sns_rooster/screens/admin/admin_dashboard_screen.dart';
import 'package:sns_rooster/screens/admin/user_management_screen.dart';
import 'package:sns_rooster/screens/admin/attendance_management_screen.dart';
import 'package:sns_rooster/screens/admin/admin_timesheet_screen.dart';
import 'package:sns_rooster/screens/auth/forgot_password_screen.dart';
import 'package:sns_rooster/screens/employee/payroll_screen.dart';
import 'package:sns_rooster/screens/employee/analytics_screen.dart';
import 'package:sns_rooster/screens/home/home_screen.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:sns_rooster/providers/attendance_provider.dart';
import 'package:sns_rooster/providers/profile_provider.dart';
import 'package:sns_rooster/providers/leave_request_provider.dart';
import 'package:sns_rooster/providers/notification_provider.dart';
import 'package:sns_rooster/providers/leave_provider.dart';
import 'package:sns_rooster/providers/payroll_provider.dart';
import 'package:sns_rooster/providers/analytics_provider.dart';
import 'package:sns_rooster/providers/holiday_provider.dart';
import 'package:sns_rooster/providers/employee_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (context) => ProfileProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => ProfileProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AttendanceProvider>(
          create: (context) => AttendanceProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => AttendanceProvider(auth),
        ),
        ChangeNotifierProvider(create: (_) => LeaveRequestProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PayrollProvider>(
          create: (context) => PayrollProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => PayrollProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AnalyticsProvider>(
          create: (context) => AnalyticsProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => AnalyticsProvider(auth),
        ),
        ChangeNotifierProvider(create: (_) => HolidayProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'SNS HR',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E88E5),
                primary: const Color(0xFF1E88E5),
                secondary: const Color(0xFF42A5F5),
                error: Colors.red,
                background: Colors.grey[50],
                surface: Colors.white,
              ),
              fontFamily: 'ProductSans',
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF1E88E5),
                    width: 2,
                  ),
                ),
              ),
            ),
            home: authProvider.isAuthenticated
                ? (authProvider.user?['role'] == 'admin'
                    ? const AdminDashboardScreen()
                    : const EmployeeDashboardScreen())
                : const SplashScreen(),
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/timesheet': (context) => const TimesheetScreen(),
              '/attendance': (context) => const AttendanceScreen(),
              '/leave_request': (context) => const LeaveRequestScreen(),
              '/notification': (context) => const NotificationScreen(),
              '/payroll': (context) => const PayrollScreen(),
              '/analytics': (context) => const AnalyticsScreen(),
              '/admin_dashboard': (context) => const AdminDashboardScreen(),
              '/employee_dashboard': (context) =>
                  const EmployeeDashboardScreen(),
              '/user_management': (context) => const UserManagementScreen(),
              '/attendance_management': (context) =>
                  const AttendanceManagementScreen(),
              '/admin_timesheet': (context) => const AdminTimesheetScreen(),
              '/forgot_password': (context) => const ForgotPasswordScreen(),
            },
            onGenerateRoute: (settings) {
              // Handle any dynamic routes here
              return null;
            },
            navigatorKey: GlobalKey<NavigatorState>(),
          );
        },
      ),
    );
  }
}
