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
import 'package:sns_rooster/screens/admin/break_management_screen.dart';
import 'package:sns_rooster/screens/admin/break_types_screen.dart';
import 'package:sns_rooster/screens/auth/forgot_password_screen.dart';
import 'package:sns_rooster/screens/employee/payroll_screen.dart';
import 'package:sns_rooster/screens/employee/analytics_screen.dart';
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
import 'package:sns_rooster/services/employee_service.dart';

void main() {
  print('MAIN: Initializing navigatorKey');
  print('MAIN: Starting MyApp with AuthProvider');
  runApp(
    Provider<RouteObserver<ModalRoute<void>>>(
      create: (_) => RouteObserver<ModalRoute<void>>(),
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('MAIN: Building MaterialApp with navigatorKey');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) {
          final authProvider = AuthProvider();
          final profileProvider = ProfileProvider(authProvider);
          authProvider.setProfileProvider(profileProvider);
          return authProvider;
        }),
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
        ChangeNotifierProvider(create: (context) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final employeeService = EmployeeService(authProvider);
          return EmployeeProvider(employeeService);
        }),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (context) => ProfileProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => previous!,
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Builder(
            builder: (context) {
              print('MAIN: AuthProvider is accessible in MaterialApp');
              return MaterialApp(
                navigatorKey: navigatorKey,
                title: 'SNS HR',
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                  useMaterial3: true,
                ),
                navigatorObservers: [Provider.of<RouteObserver<ModalRoute<void>>>(context)],
                initialRoute: '/splash',
                routes: {
                  '/splash': (context) => const SplashScreen(),
                  '/login': (context) => const LoginScreen(),
                  '/admin_dashboard': (context) => const AdminDashboardScreen(),
                  '/employee_dashboard': (context) => const EmployeeDashboardScreen(),
                  '/forgot_password': (context) => const ForgotPasswordScreen(),
                  '/timesheet': (context) => const TimesheetScreen(),
                  '/leave_request': (context) => const LeaveRequestScreen(),
                  '/attendance': (context) => const AttendanceScreen(),
                  '/payroll': (context) => const PayrollScreen(),
                  '/analytics': (context) => const AnalyticsScreen(),
                  '/profile': (context) => const ProfileScreen(),
                  '/notification': (context) => const NotificationScreen(),
                  '/break_management': (context) => const BreakManagementScreen(),
                  '/break_types': (context) => const BreakTypesScreen(),
                },
              );
            },
          );
        },
      ),
    );
  }
}
