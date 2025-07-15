import 'package:sns_rooster/services/dynamic_api_service.dart';
import 'package:sns_rooster/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FakeHttpClient extends http.BaseClient {
  int callCount = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    // Simulate /auth/refresh endpoint
    if (request.url.path.endsWith('/auth/refresh')) {
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({
          'token': 'new_valid_token',
          'refreshToken': 'new_refresh_token',
        }))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    // Simulate normal API endpoint
    return http.StreamedResponse(
      Stream.value(utf8.encode('OK')), 200);
  }
}

class TestableDynamicApiService extends DynamicApiService {
  TestableDynamicApiService() : super.testable();
  String? testBaseUrl;
  @override
  Future<String> get baseUrl async => testBaseUrl ?? await super.baseUrl;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('DynamicApiService Integration', () {
    late FakeHttpClient fakeClient;
    late TestableDynamicApiService service;

    setUp(() async {
      fakeClient = FakeHttpClient();
      service = TestableDynamicApiService();
      service.httpClient = fakeClient;
      service.testBaseUrl = 'http://localhost/';
      await SecureStorageService.clearAllData();
      await SecureStorageService.storeAuthToken(
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJleHAiOjE2MDAwMDAwMDB9.'
        'expiredsig',
      );
      await SecureStorageService.storeRefreshToken('dummy_refresh_token');
    });

    tearDown(() async {
      await SecureStorageService.clearAllData();
    });

    testWidgets('Should refresh token and proceed with API call', (tester) async {
      final tokenBefore = await SecureStorageService.getAuthToken();
      expect(tokenBefore, isNot('new_valid_token'));
      // Call a public API method that triggers token refresh
      final response = await service.get('test-endpoint');
      final tokenAfter = await SecureStorageService.getAuthToken();
      expect(tokenAfter, 'new_valid_token');
      expect(response.statusCode, 200);
    });
  });
}
