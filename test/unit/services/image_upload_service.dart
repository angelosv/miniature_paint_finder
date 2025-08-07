import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniature_paint_finder/services/image_upload_service.dart';

import 'image_upload_service.mocks.dart';

@GenerateMocks([http.Client, FirebaseAuth, User])
void main() {
  late MockClient mockClient;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late ImageUploadService service;
  late File tempFile;

  setUp(() {
    mockClient = MockClient();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Stub FirebaseAuth to return a user with a fake token
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.getIdToken()).thenAnswer((_) async => 'fake-token');

    // Instantiate service with injected client and auth
    service = ImageUploadService(
      baseUrl: 'https://example.com',
      client: mockClient,
      auth: mockAuth,
    );

    // Create a temporary file for upload
    final directory = Directory.systemTemp;
    tempFile = File('${directory.path}/test_upload.txt');
    tempFile.writeAsStringSync('dummy data');
  });

  tearDown(() {
    // Clean up the temp file
    if (tempFile.existsSync()) {
      tempFile.deleteSync();
    }
  });

  test('returns URL on successful upload (status 200)', () async {
    // Prepare a streamed response with status 200 and a JSON body containing "url"
    final streamedResponse = http.StreamedResponse(
      Stream.value(utf8.encode(json.encode({'url': 'uploaded-url'}))),
      200,
    );
    when(mockClient.send(any)).thenAnswer((_) async => streamedResponse);

    final result = await service.uploadImage(tempFile);
    expect(result, equals('uploaded-url'));
  });

  test('throws exception on non-200 status code', () async {
    // Prepare a successful JSON body but with status 500
    final streamedResponse = http.StreamedResponse(
      Stream.value(utf8.encode(json.encode({'url': 'uploaded-url'}))),
      500,
    );
    when(mockClient.send(any)).thenAnswer((_) async => streamedResponse);

    expect(
      () async => await service.uploadImage(tempFile),
      throwsA(isA<Exception>()),
    );
  });

  test('throws exception when client.send throws', () async {
    when(mockClient.send(any)).thenThrow(Exception('network error'));

    expect(
      () async => await service.uploadImage(tempFile),
      throwsA(isA<Exception>()),
    );
  });
}
