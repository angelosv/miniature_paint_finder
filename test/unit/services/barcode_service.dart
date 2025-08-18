// test/barcode_service_test.dart

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import 'package:miniature_paint_finder/services/barcode_service.dart';

import 'barcode_service.mocks.dart';

@GenerateMocks([http.Client, FirebaseAuth, User])
void main() {
  late MockClient mockClient;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late BarcodeService service;

  setUp(() {
    mockClient = MockClient();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Stub currentUser and token retrieval
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.getIdToken()).thenAnswer((_) async => 'fake-token');

    service = BarcodeService(
      baseUrl: 'https://example.com/api',
      client: mockClient,
      auth: mockAuth,
    );
  });

  group('isValidBarcode', () {
    test('returns true for valid numeric barcode', () {
      expect(service.isValidBarcode(' 1234567890123 '), isTrue);
    });

    test('returns false for too short barcode', () {
      expect(service.isValidBarcode('12345'), isFalse);
    });

    test('returns true for codes starting with PAINT', () {
      expect(service.isValidBarcode('paint-XYZ'), isTrue);
    });

    test('returns true for alphanumeric manufacturer codes', () {
      expect(service.isValidBarcode('ABCD1234'), isTrue);
      expect(service.isValidBarcode('A1'), isFalse);
    });
  });

  group('findPaintByBarcode', () {
    test('returns null for empty barcode', () async {
      expect(await service.findPaintByBarcode('', true), isNull);
    });

    test('parses successful guest response', () async {
      final fakeResponse = {
        'executed': true,
        'data': [
          {
            'id': '1',
            'brand': 'TestBrand',
            'brandId': 'B1',
            'name': 'Red Paint',
            'code': 'RP01',
            'set': 'S1',
            'r': 255,
            'g': 0,
            'b': 0,
            'hex': '#FF0000',
            'category': 'color',
            'isMetallic': false,
            'isTransparent': false,
            'palettes': ['warm', 'bright'],
          },
        ],
      };

      final uri = Uri.parse('https://example.com/api/paint/barcode/123456');
      when(
        mockClient.get(uri, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response(json.encode(fakeResponse), 200));

      final paints = await service.findPaintByBarcode('123-456', true);
      expect(paints, isNotNull);
      expect(paints!.first.name, 'Red Paint');
      expect(paints.first.palettes, ['warm', 'bright']);
    });

    test('returns null on HTTP error', () async {
      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('Error', 404));

      final paints = await service.findPaintByBarcode('000000', true);
      expect(paints, isNull);
    });

    test('includes token for authenticated user', () async {
      final fakeResponse = {'executed': false, 'data': []};
      when(
        mockClient.get(
          any,
          headers: argThat(
            containsPair('Authorization', 'Bearer fake-token'),
            named: 'headers',
          ),
        ),
      ).thenAnswer((_) async => http.Response(json.encode(fakeResponse), 200));

      final paints = await service.findPaintByBarcode('ABC123', false);
      expect(paints, isNull);
    });

    test('returns null if no current user', () async {
      when(mockAuth.currentUser).thenReturn(null);

      final paints = await service.findPaintByBarcode('XYZ', false);
      expect(paints, isNull);
    });
  });
}
