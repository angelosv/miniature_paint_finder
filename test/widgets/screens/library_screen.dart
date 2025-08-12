// test/services/paint_api_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:miniature_paint_finder/services/paint_api_service.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/paint_submit.dart';

import 'library_screen.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient client;
  late PaintApiService service;

  setUp(() {
    client = MockClient();
    service = PaintApiService(client: client);
  });

  group('getPaints', () {
    test('returns parsed paints on 200', () async {
      final body = {
        "paints": [
          {
            "id": "1",
            "name": "Red",
            "code": "R01",
            "brandId": "b1",
            "hex": "#ff0000",
          },
        ],
        "currentPage": 1,
        "totalPaints": 1,
        "totalPages": 1,
        "limit": 10,
      };

      when(
        client.get(any),
      ).thenAnswer((_) async => http.Response(jsonEncode(body), 200));

      final result = await service.getPaints(limit: 10);
      final paints = result['paints'] as List<Paint>;

      expect(paints, isA<List<Paint>>());
      expect(paints.first.name, 'Red');
      expect(result['totalPaints'], 1);
      expect(result['limit'], 10);
    });

    test('throws on non-200', () async {
      when(client.get(any)).thenAnswer((_) async => http.Response('oops', 500));
      expect(() => service.getPaints(), throwsA(isA<Exception>()));
    });
  });

  group('getBrands', () {
    test('normalizes paint_count from paintCount', () async {
      final body = [
        {"name": "BrandX", "paintCount": 5},
      ];

      when(
        client.get(any),
      ).thenAnswer((_) async => http.Response(jsonEncode(body), 200));

      final brands = await service.getBrands();
      expect(brands.first['paint_count'], 5);
      expect(brands.first['name'], 'BrandX');
    });

    test('normalizes paint_count from paints_count', () async {
      final body = [
        {"name": "BrandY", "paints_count": "7"},
      ];

      when(
        client.get(any),
      ).thenAnswer((_) async => http.Response(jsonEncode(body), 200));

      final brands = await service.getBrands();
      expect(brands.first['paint_count'], 7);
    });

    test('defaults paint_count to 0 when missing', () async {
      final body = [
        {"name": "BrandZ"},
      ];

      when(
        client.get(any),
      ).thenAnswer((_) async => http.Response(jsonEncode(body), 200));

      final brands = await service.getBrands();
      expect(brands.first['paint_count'], 0);
    });

    test('throws on non-200', () async {
      when(client.get(any)).thenAnswer((_) async => http.Response('err', 404));
      expect(() => service.getBrands(), throwsA(isA<Exception>()));
    });
  });

  group('getCategories', () {
    test('returns list of maps on 200', () async {
      final body = {
        "data": [
          {"id": "cat1", "name": "Category 1"},
        ],
      };

      when(
        client.get(any),
      ).thenAnswer((_) async => http.Response(jsonEncode(body), 200));

      final categories = await service.getCategories();
      expect(categories, isA<List<Map<String, dynamic>>>());
      expect(categories.first['name'], 'Category 1');
    });

    test('throws on non-200', () async {
      when(client.get(any)).thenAnswer((_) async => http.Response('nope', 403));
      expect(() => service.getCategories(), throwsA(isA<Exception>()));
    });
  });

  group('submitPaint', () {
    test('returns true on 200', () async {
      final item = PaintSubmit(
        imageUrl: 'https://example.com/img.png',
        brandId: 'brand-123',
        barcode: 'EAN-999999',
        name: 'Ultramarine Blue',
        status: 'pending',
      );

      when(
        client.post(any, headers: anyNamed('headers'), body: anyNamed('body')),
      ).thenAnswer((_) async => http.Response('', 200));

      final ok = await service.submitPaint(item);
      expect(ok, isTrue);
    });

    test('returns true on 201', () async {
      final item = PaintSubmit(
        imageUrl: 'https://example.com/img.png',
        brandId: 'brand-123',
        barcode: 'EAN-999999',
        name: 'Ultramarine Blue',
        status: 'pending',
      );

      when(
        client.post(any, headers: anyNamed('headers'), body: anyNamed('body')),
      ).thenAnswer((_) async => http.Response('', 201));

      final ok = await service.submitPaint(item);
      expect(ok, isTrue);
    });

    test('returns false on non-2xx', () async {
      final item = PaintSubmit(
        imageUrl: 'https://example.com/img.png',
        brandId: 'brand-123',
        barcode: 'EAN-999999',
        name: 'Ultramarine Blue',
        status: 'pending',
      );

      when(
        client.post(any, headers: anyNamed('headers'), body: anyNamed('body')),
      ).thenAnswer((_) async => http.Response('bad', 400));

      final ok = await service.submitPaint(item);
      expect(ok, isFalse);
    });

    test('returns false on exception', () async {
      final item = PaintSubmit(
        imageUrl: 'https://example.com/img.png',
        brandId: 'brand-123',
        barcode: 'EAN-999999',
        name: 'Ultramarine Blue',
        status: 'pending',
      );

      when(
        client.post(any, headers: anyNamed('headers'), body: anyNamed('body')),
      ).thenThrow(Exception('network'));

      final ok = await service.submitPaint(item);
      expect(ok, isFalse);
    });
  });
}
