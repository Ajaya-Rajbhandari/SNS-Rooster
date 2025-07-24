import 'package:sns_rooster/providers/feature_provider.dart';

/// Test utility to verify subscription-based features
class SubscriptionFeaturesTest {
  /// Test the subscription feature system
  static void testSubscriptionFeatures(FeatureProvider featureProvider) {
    print('🔍 Testing Subscription-Based Features...');

    print(
        '📊 Current Subscription Plan: ${featureProvider.subscriptionPlanName}');
    print(
        '📊 Company Status: ${featureProvider.isCompanyActive ? "Active" : "Inactive"}');

    print('\n📍 Location Management Features:');
    print(
        '   - Location Management: ${featureProvider.hasLocationManagement ? "✅ Available" : "❌ Not Available"}');
    print(
        '   - Location Settings: ${featureProvider.hasLocationSettings ? "✅ Available" : "❌ Not Available"}');
    print(
        '   - Location Notifications: ${featureProvider.hasLocationNotifications ? "✅ Available" : "❌ Not Available"}');
    print(
        '   - Location Geofencing: ${featureProvider.hasLocationGeofencing ? "✅ Available" : "❌ Not Available"}');
    print(
        '   - Location Capacity: ${featureProvider.hasLocationCapacity ? "✅ Available" : "❌ Not Available"}');
    print(
        '   - Location-Based Attendance: ${featureProvider.hasLocationBasedAttendance ? "✅ Available" : "❌ Not Available"}');

    print('\n🎯 Basic Features (Always Available):');
    print(
        '   - Attendance: ${featureProvider.hasAttendance ? "✅ Available" : "❌ Not Available"}');
    print('   - Profile: ✅ Always Available');
    print(
        '   - Notifications: ${featureProvider.hasNotifications ? "✅ Available" : "❌ Not Available"}');

    print('\n📋 Subscription Plan Details:');
    print('   - Plan Name: ${featureProvider.subscriptionPlanName}');
    print('   - Is Basic Plan: ${featureProvider.isBasicPlan}');
    print('   - Is Professional Plan: ${featureProvider.isProfessionalPlan}');
    print('   - Is Enterprise Plan: ${featureProvider.isEnterprisePlan}');

    print('\n💡 Feature Availability Summary:');
    if (featureProvider.hasLocationManagement) {
      print('✅ Full location management features are available');
    } else {
      print('❌ Location management features require subscription upgrade');
      print(
          '💡 Users can still use basic attendance without location validation');
    }

    print('\n🎉 Subscription feature test completed!');
  }
}
