import 'package:flutter/material.dart';
import 'package:sns_rooster/utils/logger.dart';
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
import 'package:sns_rooster/screens/admin/notification_alert_screen.dart';
import 'package:sns_rooster/screens/admin/leave_management_screen.dart';
import 'package:sns_rooster/screens/admin/payroll_cycle_settings_screen.dart';
import 'package:sns_rooster/screens/admin/tax_settings_screen.dart';
import 'package:sns_rooster/screens/admin/company_settings_screen.dart';
import 'package:sns_rooster/screens/admin/leave_policy_settings_screen.dart';
import 'package:sns_rooster/screens/admin/admin_profile_screen.dart';
import 'package:sns_rooster/screens/admin/admin_attendance_screen.dart';
import 'package:sns_rooster/screens/auth/reset_password_screen.dart';
import 'package:sns_rooster/screens/auth/verify_email_screen.dart';
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
import 'package:sns_rooster/providers/admin_payroll_provider.dart';
import 'package:sns_rooster/providers/admin_settings_provider.dart';
import 'package:sns_rooster/providers/admin_attendance_provider.dart';
import 'package:sns_rooster/providers/admin_analytics_provider.dart';
import 'package:sns_rooster/providers/payroll_analytics_provider.dart';
import 'package:sns_rooster/providers/payroll_cycle_settings_provider.dart';
import 'package:sns_rooster/providers/tax_settings_provider.dart';
import 'package:sns_rooster/providers/company_settings_provider.dart';
import 'package:sns_rooster/services/employee_service.dart';
import 'package:sns_rooster/services/notification_service.dart';
import 'package:sns_rooster/services/global_notification_service.dart';
import 'package:sns_rooster/services/fcm_service.dart';
import 'package:sns_rooster/widgets/global_notification_banner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'web_url_strategy_stub.dart'
    if (dart.library.html) 'web_url_strategy.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
// Add this import for web notification permission
import 'web_notification_permission_stub.dart'
    if (dart.library.html) 'web_notification_permission_web.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestAndroidNotificationPermission() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    final status = await Permission.notification.request();
    print('Android notification permission: $status');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request notification permission on web
  if (kIsWeb) {
    final permission = await requestWebNotificationPermission();
    print('Web notification permission: ' + permission.toString());
  }

  // Request Android notification permission (Android 13+)
  await requestAndroidNotificationPermission();

  // Try to get the FCM token directly (for debugging)
  String? token = await FirebaseMessaging.instance.getToken();
  print('FCM Token (main): $token');

  // Initialize FCM Service
  await FCMService().initialize();

  setWebUrlStrategy();
  log('MAIN: Initializing navigatorKey');
  log('MAIN: Starting MyApp with AuthProvider');
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    log('MAIN: Building MaterialApp with navigatorKey');
    return MultiProvider(
      providers: [
        Provider<RouteObserver<ModalRoute<void>>>(
          create: (_) => RouteObserver<ModalRoute<void>>(),
        ),
        ChangeNotifierProvider<GlobalNotificationService>(
          create: (_) => GlobalNotificationService(),
        ),
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
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(
            NotificationService(
                Provider.of<AuthProvider>(context, listen: false)),
          ),
          update: (context, auth, previous) => NotificationProvider(
            NotificationService(auth),
          ),
        ),
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
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final employeeService = EmployeeService(authProvider);
          return EmployeeProvider(employeeService);
        }),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (context) => ProfileProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => previous!,
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminPayrollProvider>(
          create: (context) => AdminPayrollProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => AdminPayrollProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminAttendanceProvider>(
          create: (context) => AdminAttendanceProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => AdminAttendanceProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminSettingsProvider>(
          create: (context) => AdminSettingsProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => AdminSettingsProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminAnalyticsProvider>(
          create: (context) => AdminAnalyticsProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => AdminAnalyticsProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PayrollAnalyticsProvider>(
          create: (context) => PayrollAnalyticsProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => PayrollAnalyticsProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PayrollCycleSettingsProvider>(
          create: (context) => PayrollCycleSettingsProvider(
              Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) =>
              PayrollCycleSettingsProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TaxSettingsProvider>(
          create: (context) => TaxSettingsProvider(
              Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => TaxSettingsProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CompanySettingsProvider>(
          create: (context) => CompanySettingsProvider(
              Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => CompanySettingsProvider(auth),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Builder(
            builder: (context) {
              log('MAIN: AuthProvider is accessible in MaterialApp');
              final adminSettings = Provider.of<AdminSettingsProvider>(context);

              final lightTheme = ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                useMaterial3: true,
                brightness: Brightness.light,
              );

              final darkTheme = ThemeData(
                colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.blue, brightness: Brightness.dark),
                useMaterial3: true,
                brightness: Brightness.dark,
              );

              return MaterialApp(
                navigatorKey: navigatorKey,
                title: 'SNS HR',
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: (authProvider.isAuthenticated &&
                        authProvider.user?['role'] == 'admin' &&
                        (adminSettings.darkModeEnabled ?? false))
                    ? ThemeMode.dark
                    : ThemeMode.light,
                navigatorObservers: [
                  Provider.of<RouteObserver<ModalRoute<void>>>(context)
                ],
                // initialRoute: '/splash',
                routes: {
                  '/': (context) => const SplashScreen(),
                  '/splash': (context) => const SplashScreen(),
                  '/login': (context) => const LoginScreen(),
                  '/admin_dashboard': (context) => const AdminDashboardScreen(),
                  '/employee_dashboard': (context) =>
                      const EmployeeDashboardScreen(),
                  '/forgot_password': (context) => const ForgotPasswordScreen(),
                  '/timesheet': (context) => const TimesheetScreen(),
                  '/leave_request': (context) => const LeaveRequestScreen(),
                  '/attendance': (context) => const AttendanceScreen(),
                  '/payroll': (context) => const PayrollScreen(),
                  '/analytics': (context) => const AnalyticsScreen(),
                  '/profile': (context) => const ProfileScreen(),
                  '/notification': (context) => const NotificationScreen(),
                  '/break_management': (context) =>
                      const BreakManagementScreen(),
                  '/break_types': (context) => const BreakTypesScreen(),
                  '/admin/notification_alerts': (context) =>
                      const NotificationAlertScreen(),
                  '/admin/leave_management': (context) =>
                      const LeaveManagementScreen(),
                  '/admin/payroll_cycle_settings': (context) =>
                      const PayrollCycleSettingsScreen(),
                  '/admin/tax_settings': (context) => const TaxSettingsScreen(),
                  '/admin/company_settings': (context) =>
                      const CompanySettingsScreen(),
                  '/admin/leave_policy_settings': (context) =>
                      const LeavePolicySettingsScreen(),
                  '/admin_profile': (context) => const AdminProfileScreen(),
                  '/admin_attendance': (context) =>
                      const AdminAttendanceScreen(),
                  '/reset-password': (context) => const ResetPasswordScreen(),
                  '/verify-email': (context) => const VerifyEmailScreen(),
                },
                builder: (context, child) {
                  if (child == null) return const SizedBox.shrink();
                  return Stack(
                    children: [
                      child,
                      const GlobalNotificationBanner(),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
