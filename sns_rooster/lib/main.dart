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
import 'package:sns_rooster/screens/admin/feature_settings_screen.dart';
import 'package:sns_rooster/screens/admin/admin_profile_screen.dart';
import 'package:sns_rooster/screens/admin/admin_attendance_screen.dart';
import 'package:sns_rooster/screens/auth/reset_password_screen.dart';
import 'package:sns_rooster/screens/auth/verify_email_screen.dart';
import 'package:sns_rooster/screens/employee/employee_events_screen.dart';
import 'package:sns_rooster/screens/employee/employee_performance_review_screen.dart';
import 'package:sns_rooster/screens/employee/employee_performance_reviews_list_screen.dart';
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
import 'package:sns_rooster/providers/company_provider.dart';
import 'package:sns_rooster/providers/super_admin_provider.dart';
import 'package:sns_rooster/providers/feature_provider.dart';
import 'package:sns_rooster/services/employee_service.dart';
import 'package:sns_rooster/services/global_notification_service.dart';
import 'package:sns_rooster/services/fcm_service.dart';
import 'package:sns_rooster/services/certificate_pinning_service.dart';
import 'package:sns_rooster/services/app_update_service.dart';
import 'package:sns_rooster/widgets/global_notification_banner.dart';
import 'package:sns_rooster/widgets/feature_initializer.dart';
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
import 'package:sns_rooster/services/api_service.dart';
import 'package:sns_rooster/config/api_config.dart';
import 'package:sns_rooster/config/debug_config.dart';
import 'package:sns_rooster/screens/admin/edit_company_form_screen.dart';
import 'package:sns_rooster/screens/admin/location_management_screen.dart';
import 'package:sns_rooster/screens/admin/expense_management_screen.dart';
import 'utils/global_navigator.dart';

Future<void> requestAndroidNotificationPermission() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    final status = await Permission.notification.request();
    Logger.info('Android notification permission: $status');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler for Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    Logger.error('FlutterError: ${details.exception}', details.stack);
  };

  Logger.info('Application starting');

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Logger.info('Firebase initialized');
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      Logger.info('Firebase already initialized');
    } else {
      Logger.warning('Firebase initialization failed: $e');
    }
  }

  Logger.info('Firebase initialized');

  // Initialize Certificate Pinning Service
  try {
    await CertificatePinningService.initialize();
    Logger.info('Certificate pinning initialized');
  } catch (e) {
    Logger.warning('Certificate pinning initialization failed: $e');
    // Continue without certificate pinning for compatibility
  }

  // Request notification permission on web
  if (kIsWeb) {
    try {
      final permission = await requestWebNotificationPermission();
      Logger.info('Web notification permission: $permission');
    } catch (e) {
      Logger.warning('Web notification permission failed: $e');
      // Continue without notifications for iOS Safari compatibility
    }
  }

  // Request Android notification permission (Android 13+)
  await requestAndroidNotificationPermission();

  // Try to get the FCM token directly (for debugging)
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      Logger.info('FCM: Token ready');
    }
  } catch (e) {
    Logger.warning('FCM token generation failed: $e');
    // Continue without FCM for iOS Safari compatibility
  }

  // Initialize FCM Service with error handling
  try {
    await FCMService().initialize();
  } catch (e) {
    Logger.warning('FCM Service initialization failed: $e');
    // Continue without FCM for iOS Safari compatibility
  }

  setWebUrlStrategy();

  // Debug configuration
  DebugConfig.printEnvironmentInfo();

  Logger.info('Starting SNS Rooster application');
  runApp(const MyApp());

  // Check for app updates after app starts
  Future.delayed(const Duration(seconds: 3), () {
    AppUpdateService.checkForUpdates(showAlert: true);
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalNavigator.navigatorKey;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<RouteObserver<ModalRoute<void>>>(
          create: (_) => RouteObserver<ModalRoute<void>>(),
        ),
        ChangeNotifierProvider<GlobalNotificationService>(
          create: (_) => GlobalNotificationService(),
        ),
        // Create AuthProvider first
        ChangeNotifierProvider(create: (context) {
          // Create the providers
          final authProvider = AuthProvider();
          final profileProvider = ProfileProvider(authProvider);
          final companyProvider = CompanyProvider();
          final companySettingsProvider = CompanySettingsProvider(authProvider);
          final featureProvider = FeatureProvider(authProvider);

          // Set up the providers
          authProvider.setProfileProvider(profileProvider);
          authProvider.setCompanyProvider(companyProvider);
          authProvider.setCompanySettingsProvider(companySettingsProvider);
          authProvider.setFeatureProvider(featureProvider);

          // Load features immediately if user is already authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              if (authProvider.isAuthenticated) {
                Logger.info('Loading features for authenticated user');
                featureProvider.loadFeatures().catchError((e) {
                  Logger.error('Failed to load features: $e');
                });
              }
            } catch (e) {
              Logger.error('Error in post-frame feature loading: $e');
            }
          });

          return authProvider;
        }),
        // Then create FeatureProvider that depends on AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, FeatureProvider>(
          create: (context) => FeatureProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              previous ?? FeatureProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AttendanceProvider>(
          create: (context) => AttendanceProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => AttendanceProvider(auth),
        ),
        ChangeNotifierProvider(create: (_) => LeaveRequestProvider()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => NotificationProvider(auth),
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
          final apiService = ApiService(baseUrl: ApiConfig.baseUrl);
          final employeeService = EmployeeService(apiService);
          return EmployeeProvider(employeeService);
        }),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (context) => ProfileProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              previous ?? ProfileProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CompanyProvider>(
          create: (context) => CompanyProvider(),
          update: (context, auth, previous) => previous ?? CompanyProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CompanySettingsProvider>(
          create: (context) =>
              CompanySettingsProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              previous ?? CompanySettingsProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SuperAdminProvider>(
          create: (context) => SuperAdminProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              previous ?? SuperAdminProvider(auth),
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
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Builder(
            builder: (context) {
              final adminSettings = Provider.of<AdminSettingsProvider>(context);

              final lightTheme = ThemeData(
                colorScheme: const ColorScheme(
                  brightness: Brightness.light,
                  primary: Color(0xFF1976D2), // Vibrant blue
                  onPrimary: Colors.white,
                  secondary: Color(0xFF2196F3), // Bright blue
                  onSecondary: Colors.white,
                  tertiary: Color(0xFF03A9F4), // Light blue
                  onTertiary: Colors.white,
                  error: Color(0xFFD32F2F), // Vibrant red
                  onError: Colors.white,
                  surface: Colors.white,
                  onSurface: Color(0xFF212121),
                  surfaceContainerHighest: Color(0xFFF5F5F5),
                  onSurfaceVariant: Color(0xFF424242),
                  outline: Color(0xFFBDBDBD),
                  outlineVariant: Color(0xFFE0E0E0),
                  shadow: Color(0xFF000000),
                  scrim: Color(0xFF000000),
                  inverseSurface: Color(0xFF303030),
                  onInverseSurface: Colors.white,
                  inversePrimary: Color(0xFF90CAF9),
                  surfaceTint: Color(0xFF1976D2),
                ),
                useMaterial3: true,
                brightness: Brightness.light,
              );

              final darkTheme = ThemeData(
                colorScheme: const ColorScheme(
                  brightness: Brightness.dark,
                  primary: Color(0xFF90CAF9), // Light blue for dark theme
                  onPrimary: Color(0xFF0D47A1),
                  secondary: Color(0xFF81D4FA), // Lighter blue
                  onSecondary: Color(0xFF01579B),
                  tertiary: Color(0xFF4FC3F7), // Bright light blue
                  onTertiary: Color(0xFF002F6C),
                  error: Color(0xFFEF5350), // Bright red for dark theme
                  onError: Color(0xFFB71C1C),
                  surface: Color(0xFF121212),
                  onSurface: Colors.white,
                  surfaceContainerHighest: Color(0xFF1E1E1E),
                  onSurfaceVariant: Color(0xFFE0E0E0),
                  outline: Color(0xFF424242),
                  outlineVariant: Color(0xFF2E2E2E),
                  shadow: Color(0xFF000000),
                  scrim: Color(0xFF000000),
                  inverseSurface: Color(0xFFE0E0E0),
                  onInverseSurface: Color(0xFF121212),
                  inversePrimary: Color(0xFF1976D2),
                  surfaceTint: Color(0xFF90CAF9),
                ),
                useMaterial3: true,
                brightness: Brightness.dark,
              );

              return FeatureInitializer(
                child: MaterialApp(
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
                    '/admin_dashboard': (context) =>
                        const AdminDashboardScreen(),
                    '/employee_dashboard': (context) =>
                        const EmployeeDashboardScreen(),
                    '/forgot_password': (context) =>
                        const ForgotPasswordScreen(),
                    '/timesheet': (context) => const TimesheetScreen(),
                    '/leave_request': (context) => const LeaveRequestScreen(),
                    '/attendance': (context) => const AttendanceScreen(),
                    '/payroll': (context) => const PayrollScreen(),
                    '/analytics': (context) => const AnalyticsScreen(),
                    '/events': (context) => const EmployeeEventsScreen(),
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
                    '/admin/tax_settings': (context) =>
                        const TaxSettingsScreen(),
                    '/admin/company_settings': (context) =>
                        const CompanySettingsScreen(),
                    '/admin/edit_company_form': (context) =>
                        const EditCompanyFormScreen(),
                    '/admin/leave_policy_settings': (context) =>
                        const LeavePolicySettingsScreen(),
                    '/admin/feature_settings': (context) =>
                        const FeatureSettingsScreen(),
                    '/admin_profile': (context) => const AdminProfileScreen(),
                    '/admin_attendance': (context) =>
                        const AdminAttendanceScreen(),
                    '/location_management': (context) =>
                        const LocationManagementScreen(),
                    '/expense_management': (context) =>
                        const ExpenseManagementScreen(),
                    '/reset-password': (context) => const ResetPasswordScreen(),
                    '/verify-email': (context) => const VerifyEmailScreen(),
                    '/performance_reviews': (context) =>
                        const EmployeePerformanceReviewsListScreen(),
                  },
                  onGenerateRoute: (settings) {
                    // Handle dynamic routes for performance reviews
                    if (settings.name
                            ?.startsWith('/employee_performance_review/') ==
                        true) {
                      final reviewId = settings.name!.split('/').last;
                      return MaterialPageRoute(
                        builder: (context) =>
                            EmployeePerformanceReviewScreen(reviewId: reviewId),
                      );
                    }
                    return null;
                  },
                  builder: (context, child) {
                    if (child == null) return const SizedBox.shrink();
                    return Stack(
                      children: [
                        child,
                        const GlobalNotificationBanner(),
                        // UpdateAlertWidget will be shown via dialog when needed
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
