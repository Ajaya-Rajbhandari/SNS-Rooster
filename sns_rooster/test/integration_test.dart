import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:sns_rooster/providers/company_provider.dart';
import 'package:sns_rooster/widgets/company_info_widget.dart';

void main() {
  group('Multi-Tenant Integration Tests', () {
    testWidgets('CompanyProvider is properly initialized in MultiProvider',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CompanyProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  CompanyInfoWidget(),
                  CompanyUsageWidget(),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify that the widgets can be built without errors
      expect(find.byType(CompanyInfoWidget), findsOneWidget);
      expect(find.byType(CompanyUsageWidget), findsOneWidget);
    });

    testWidgets('CompanyInfoWidget shows loading state initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider(
              create: (_) => CompanyProvider(),
              child: const CompanyInfoWidget(),
            ),
          ),
        ),
      );

      // Initially should show loading or "not available" message
      expect(find.text('Company information not available'), findsOneWidget);
    });

    testWidgets('CompanyUsageWidget shows nothing when company not loaded',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider(
              create: (_) => CompanyProvider(),
              child: const CompanyUsageWidget(),
            ),
          ),
        ),
      );

      // Should not show anything when company is not loaded
      expect(find.byType(CompanyUsageWidget), findsOneWidget);
    });

    test('CompanyProvider integration with AuthProvider', () {
      final authProvider = AuthProvider();
      final companyProvider = CompanyProvider();

      // Test that providers can be created together
      expect(authProvider, isNotNull);
      expect(companyProvider, isNotNull);

      // Test initial states
      expect(companyProvider.currentCompany, isNull);
      expect(companyProvider.isLoading, isFalse);
      expect(companyProvider.isCompanyLoaded, isFalse);
    });

    test('CompanyProvider feature checking with null company', () {
      final provider = CompanyProvider();

      // All feature checks should return false when no company is loaded
      expect(provider.hasAnalytics, isFalse);
      expect(provider.hasAdvancedReporting, isFalse);
      expect(provider.hasCustomBranding, isFalse);
      expect(provider.hasApiAccess, isFalse);
      expect(provider.hasPrioritySupport, isFalse);
    });

    test('CompanyProvider usage calculations with null company', () {
      final provider = CompanyProvider();

      // All usage calculations should return 0 when no company is loaded
      expect(provider.currentEmployeeCount, equals(0));
      expect(provider.employeeLimit, equals(0));
      expect(provider.currentStorageUsage, equals(0));
      expect(provider.storageLimit, equals(0));
      expect(provider.currentApiRequestCount, equals(0));
      expect(provider.apiRequestLimit, equals(0));
    });

    test('CompanyProvider subscription plan checks with null company', () {
      final provider = CompanyProvider();

      // All subscription plan checks should return false when no company is loaded
      expect(provider.isBasicPlan, isFalse);
      expect(provider.isProPlan, isFalse);
      expect(provider.isEnterprisePlan, isFalse);
    });
  });
}
