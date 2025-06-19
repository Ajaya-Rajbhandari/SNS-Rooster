import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sns_rooster/providers/profile_provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart';

void main() {
  group('ProfileProvider Tests', () {
    late ProfileProvider profileProvider;
    late AuthProvider authProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      authProvider = AuthProvider();
      profileProvider = ProfileProvider(authProvider);
      print('Test Setup: SharedPreferences initialized');
    });

    test('Should save profile to shared preferences', () async {
      final mockProfile = {
        'name': 'John Doe',
        'email': 'john.doe@example.com',
        'role': 'employee'
      };

      print('Test: Updating profile with mock data: $mockProfile');
      profileProvider.updateProfile(mockProfile);

      final prefs = await SharedPreferences.getInstance();
      final savedProfile = prefs.getString('user_profile');

      print('Test: Saved profile in SharedPreferences: $savedProfile');

      expect(savedProfile, isNotNull);
      expect(savedProfile, contains('John Doe'));
    });

    test('Should handle null profile gracefully', () async {
      profileProvider.updateProfile({}); // Pass an empty map instead of null

      final prefs = await SharedPreferences.getInstance();
      final savedProfile = prefs.getString('user_profile');

      expect(savedProfile, isNull);
    });

    test('Should fetch profile correctly', () async {
      // Mock backend response
      final mockProfile = {
        'name': 'John Doe',
        'email': 'john.doe@example.com',
        'role': 'employee'
      };

      profileProvider.updateProfile(mockProfile);

      expect(profileProvider.profile, isNotNull);
      expect(profileProvider.profile!['name'], 'John Doe');
    });
  });
}
