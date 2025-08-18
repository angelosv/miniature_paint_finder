import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:miniature_paint_finder/services/api_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_screen.mocks.dart';

@GenerateMocks([http.Client, FirebaseAuth, User])
void main() {
  late MockClient mockClient;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late ApiService apiService;

  setUp(() {
    mockClient = MockClient();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.getIdToken()).thenAnswer((_) async => 'fake-token');

    apiService = ApiService(
      baseUrl: 'https://example.com/api/',
      client: mockClient,
      auth: mockAuth,
    );
  });

  group('GET', () {
    test('returns JSON on status 200', () async {
      final mockResponse = {'message': 'ok'};

      when(
        mockClient.get(
          Uri.parse('https://example.com/api/test'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

      final result = await apiService.get('test');

      expect(result, isA<Map<String, dynamic>>());
      expect(result['message'], 'ok');
    });

    test('throws exception on 404', () async {
      when(
        mockClient.get(
          Uri.parse('https://example.com/api/notfound'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('Not found', 404));

      expect(
        () async => await apiService.get('notfound'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('POST', () {
    test('returns JSON on status 200', () async {
      final requestData = {'key': 'value'};
      final responseData = {'status': 'ok'};

      when(
        mockClient.post(
          Uri.parse('https://example.com/api/post-endpoint'),
          headers: anyNamed('headers'),
          body: json.encode(requestData),
        ),
      ).thenAnswer((_) async => http.Response(json.encode(responseData), 200));

      final result = await apiService.post('post-endpoint', requestData);

      expect(result, isA<Map<String, dynamic>>());
      expect(result['status'], equals('ok'));
    });

    test('throws exception on 500', () async {
      final requestData = {'error': 'true'};

      when(
        mockClient.post(
          Uri.parse('https://example.com/api/post-error'),
          headers: anyNamed('headers'),
          body: json.encode(requestData),
        ),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () async => await apiService.post('post-error', requestData),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PUT', () {
    test('returns JSON on status 200', () async {
      final requestData = {'update': true};
      final responseData = {'updated': true};

      when(
        mockClient.put(
          Uri.parse('https://example.com/api/put-endpoint'),
          headers: anyNamed('headers'),
          body: json.encode(requestData),
        ),
      ).thenAnswer((_) async => http.Response(json.encode(responseData), 200));

      final result = await apiService.put('put-endpoint', requestData);

      expect(result, isA<Map<String, dynamic>>());
      expect(result['updated'], isTrue);
    });

    test('throws exception on 403', () async {
      when(
        mockClient.put(
          Uri.parse('https://example.com/api/put-forbidden'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response('Forbidden', 403));

      expect(
        () async => await apiService.put('put-forbidden', {}),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('DELETE', () {
    test('returns null on 200 with empty body', () async {
      when(
        mockClient.delete(
          Uri.parse('https://example.com/api/delete-endpoint'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('', 200));

      final result = await apiService.delete('delete-endpoint');

      expect(result, isNull);
    });

    test('throws exception on 401', () async {
      when(
        mockClient.delete(
          Uri.parse('https://example.com/api/delete-unauthorized'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('Unauthorized', 401));

      expect(
        () async => await apiService.delete('delete-unauthorized'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
