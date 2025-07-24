import 'package:flutter_test/flutter_test.dart';
import 'package:sns_rooster/models/company.dart';
import 'package:sns_rooster/providers/company_provider.dart';
import 'package:sns_rooster/services/company_service.dart';
import 'package:sns_rooster/services/secure_storage_service.dart';

void main() {
  group('Multi-Tenant Frontend Tests', () {
    test('Company model creation and serialization', () {
      final companyData = {
        '_id': 'test-company-id',
        'name': 'Test Company',
        'domain': 'testcompany.com',
        'subdomain': 'test',
        'adminEmail': 'admin@testcompany.com',
        'contactPhone': '+1234567890',
        'address': '123 Test St, Test City',
        'subscriptionPlan': 'pro',
        'features': {
          'analytics': true,
          'advancedReporting': true,
          'customBranding': false,
          'apiAccess': true,
          'prioritySupport': false,
        },
        'limits': {
          'employees': 50,
          'storage': 1000,
          'apiRequests': 10000,
        },
        'usage': {
          'employees': 25,
          'storage': 500,
          'apiRequests': 5000,
        },
        'status': 'active',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final company = Company.fromJson(companyData);

      expect(company.id, equals('test-company-id'));
      expect(company.name, equals('Test Company'));
      expect(company.domain, equals('testcompany.com'));
      expect(company.subscriptionPlan, equals('pro'));
      expect(company.isProPlan(), isTrue);
      expect(company.isBasicPlan(), isFalse);
      expect(company.isEnterprisePlan(), isFalse);
      expect(company.isActive, isTrue);

      // Test feature flags
      expect(company.hasFeature('analytics'), isTrue);
      expect(company.hasFeature('advancedReporting'), isTrue);
      expect(company.hasFeature('customBranding'), isFalse);
      expect(company.hasFeature('apiAccess'), isTrue);
      expect(company.hasFeature('prioritySupport'), isFalse);

      // Test usage limits
      expect(company.getLimit('employees'), equals(50));
      expect(company.getUsage('employees'), equals(25));
      expect(company.isWithinLimit('employees'), isTrue);

      expect(company.getLimit('storage'), equals(1000));
      expect(company.getUsage('storage'), equals(500));
      expect(company.isWithinLimit('storage'), isTrue);

      expect(company.getLimit('apiRequests'), equals(10000));
      expect(company.getUsage('apiRequests'), equals(5000));
      expect(company.isWithinLimit('apiRequests'), isTrue);

      // Test JSON serialization
      final json = company.toJson();
      expect(json['id'], equals('test-company-id'));
      expect(json['name'], equals('Test Company'));
      expect(json['subscriptionPlan'], equals('pro'));
    });

    test('Company model with unlimited limits', () {
      final companyData = {
        '_id': 'unlimited-company-id',
        'name': 'Unlimited Company',
        'domain': 'unlimited.com',
        'subdomain': 'unlimited',
        'adminEmail': 'admin@unlimited.com',
        'subscriptionPlan': 'enterprise',
        'features': {
          'analytics': true,
          'advancedReporting': true,
          'customBranding': true,
          'apiAccess': true,
          'prioritySupport': true,
        },
        'limits': {
          'employees': 0, // Unlimited
          'storage': 0, // Unlimited
          'apiRequests': 0, // Unlimited
        },
        'usage': {
          'employees': 100,
          'storage': 2000,
          'apiRequests': 50000,
        },
        'status': 'active',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final company = Company.fromJson(companyData);

      expect(company.isEnterprisePlan(), isTrue);
      expect(company.getLimit('employees'), equals(0));
      expect(company.getUsage('employees'), equals(100));
      expect(company.isWithinLimit('employees'), isTrue); // 0 means unlimited

      expect(company.getLimit('storage'), equals(0));
      expect(company.getUsage('storage'), equals(2000));
      expect(company.isWithinLimit('storage'), isTrue); // 0 means unlimited
    });

    test('Company model with exceeded limits', () {
      final companyData = {
        '_id': 'exceeded-company-id',
        'name': 'Exceeded Company',
        'domain': 'exceeded.com',
        'subdomain': 'exceeded',
        'adminEmail': 'admin@exceeded.com',
        'subscriptionPlan': 'basic',
        'features': {
          'analytics': false,
          'advancedReporting': false,
          'customBranding': false,
          'apiAccess': false,
          'prioritySupport': false,
        },
        'limits': {
          'employees': 10,
          'storage': 100,
          'apiRequests': 1000,
        },
        'usage': {
          'employees': 12, // Exceeded
          'storage': 150, // Exceeded
          'apiRequests': 1200, // Exceeded
        },
        'status': 'active',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final company = Company.fromJson(companyData);

      expect(company.isBasicPlan(), isTrue);
      expect(company.getLimit('employees'), equals(10));
      expect(company.getUsage('employees'), equals(12));
      expect(company.isWithinLimit('employees'), isFalse); // Exceeded

      expect(company.getLimit('storage'), equals(100));
      expect(company.getUsage('storage'), equals(150));
      expect(company.isWithinLimit('storage'), isFalse); // Exceeded

      expect(company.getLimit('apiRequests'), equals(1000));
      expect(company.getUsage('apiRequests'), equals(1200));
      expect(company.isWithinLimit('apiRequests'), isFalse); // Exceeded
    });

    test('CompanyProvider initialization', () {
      final provider = CompanyProvider();

      expect(provider.currentCompany, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.isCompanyLoaded, isFalse);
      expect(provider.isCompanyActive, isFalse);
      expect(provider.isBasicPlan, isFalse);
      expect(provider.isProPlan, isFalse);
      expect(provider.isEnterprisePlan, isFalse);
    });

    test('CompanyProvider feature checks', () {
      final provider = CompanyProvider();

      // Test with null company
      expect(provider.isFeatureEnabled('analytics'), isFalse);
      expect(provider.isWithinLimit('employees'), isFalse);
      expect(provider.getCurrentUsage('employees'), equals(0));
      expect(provider.getLimit('employees'), equals(0));
      expect(provider.getUsagePercentage('employees'), equals(0.0));
    });

    test('CompanyProvider usage calculations', () {
      final provider = CompanyProvider();

      // Test usage percentage calculations
      expect(provider.getUsagePercentage('employees'), equals(0.0));
      expect(provider.getUsagePercentage('storage'), equals(0.0));
      expect(provider.getUsagePercentage('apiRequests'), equals(0.0));
    });
  });
}
