import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('Testing Production Backend Connection');
  print('=====================================');

  // Hardcode the production URL since we can't use Flutter config
  const String productionUrl = 'https://sns-rooster.onrender.com/api';
  print('Base URL: $productionUrl');
  print('');

  try {
    // Test 1: Check if the server is reachable
    print('Test 1: Testing server reachability...');
    final pingResponse = await http.get(
      Uri.parse('https://sns-rooster.onrender.com/'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    print('Ping Status Code: ${pingResponse.statusCode}');
    print(
        'Ping Response: ${pingResponse.body.length > 100 ? pingResponse.body.substring(0, 100) + '...' : pingResponse.body}');
    print('');

    // Test 2: Try to access the API root
    print('Test 2: Testing API root...');
    final apiResponse = await http.get(
      Uri.parse(productionUrl),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    print('API Root Status Code: ${apiResponse.statusCode}');
    print('API Root Response: ${apiResponse.body}');
    print('');

    // Test 3: Try common endpoints
    final endpoints = [
      '/users',
      '/auth/login',
      '/auth/register',
      '/attendance'
    ];

    for (final endpoint in endpoints) {
      print('Test 3: Testing endpoint $endpoint...');
      try {
        final response = await http.get(
          Uri.parse('$productionUrl$endpoint'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));

        print('Status Code: ${response.statusCode}');
        print(
            'Response: ${response.body.length > 50 ? response.body.substring(0, 50) + '...' : response.body}');
        print('');
      } catch (e) {
        print('Error: $e');
        print('');
      }
    }

    print('✅ Backend connection test completed!');
    print('Your production backend is reachable.');
  } catch (e) {
    print('❌ Error connecting to production backend:');
    print('Error: $e');
    print('');
    print('Troubleshooting tips:');
    print('1. Check if your backend is deployed and running on Render');
    print('2. Verify the URL: https://sns-rooster.onrender.com');
    print('3. Check if there are any CORS issues');
    print('4. Ensure your backend endpoints are properly configured');
  }
}
