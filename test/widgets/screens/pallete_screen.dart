import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:miniature_paint_finder/services/palette_service.dart';
import 'package:miniature_paint_finder/models/most_used_paint.dart';

import 'pallete_screen.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;
  late PaletteService service;
  const token = 'fake-token';
  const baseUrl = 'https://test.api';

  setUp(() {
    mockClient = MockClient();
    service = PaletteService(baseUrl: baseUrl, client: mockClient);
  });

  group('uploadImage', () {
    test('returns data when executed is true', () async {
      final responseBody = {
        'executed': true,
        'data': {'id': 'IMG1', 'url': 'u.png'},
      };
      when(
        mockClient.post(
          Uri.parse('$baseUrl/image/upload'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      final data = await service.uploadImage('/path', token);
      expect(data, containsPair('id', 'IMG1'));
      expect(data, containsPair('url', 'u.png'));
    });

    test('throws exception when executed is false', () async {
      final responseBody = {'executed': false, 'message': 'fail'};
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      expect(
        () => service.uploadImage('/path', token),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('fail'),
          ),
        ),
      );
    });
  });

  group('createPalette', () {
    test('returns data on success', () async {
      final responseBody = {
        'executed': true,
        'data': {'id': 'PAL1'},
      };
      when(
        mockClient.post(
          Uri.parse('$baseUrl/palettes'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      final data = await service.createPalette('MyPal', token);
      expect(data, containsPair('id', 'PAL1'));
    });

    test('throws exception on failure', () async {
      final responseBody = {'executed': false, 'message': 'error'};
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      expect(
        () => service.createPalette('MyPal', token),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('error'),
          ),
        ),
      );
    });
  });

  group('getImagePicks', () {
    test('returns list when executed true', () async {
      final picks = [
        {'id': 'P1'},
        {'id': 'P2'},
      ];
      when(
        mockClient.post(
          Uri.parse('$baseUrl/image/IMG1/picks'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'executed': true, 'data': picks}), 200),
      );

      final result = await service.getImagePicks('IMG1', token, []);
      expect(result.length, 2);
      expect(result[0]['id'], 'P1');
    });

    test('throws when executed false', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'executed': false, 'message': 'oops'}),
          200,
        ),
      );

      expect(
        () => service.getImagePicks('IMG1', token, []),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('oops'),
          ),
        ),
      );
    });

    test('returns empty list when data null', () async {
      when(
        mockClient.post(
          Uri.parse('$baseUrl/image/IMG1/picks'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'executed': true, 'data': null}), 200),
      );

      final result = await service.getImagePicks('IMG1', token, []);
      expect(result, isEmpty);
    });
  });

  group('getAllPalettesNamesAndIds', () {
    test('parses returned list', () async {
      final list = [
        {'id': 'A', 'name': 'Alpha'},
        {'id': 'B', 'name': 'Beta'},
      ];
      when(
        mockClient.get(
          Uri.parse('$baseUrl/palettes/simple-list'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response(jsonEncode({'data': list}), 200));

      final result = await service.getAllPalettesNamesAndIds(token);
      expect(result, [
        {'id': 'A', 'name': 'Alpha'},
        {'id': 'B', 'name': 'Beta'},
      ]);
    });

    test('returns empty when data null', () async {
      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode({'data': null}), 200));

      final result = await service.getAllPalettesNamesAndIds(token);
      expect(result, isEmpty);
    });
  });

  group('getMostUsedPaints', () {
    test('returns list on executed true', () async {
      final raw = [
        {
          'brand_id': 'B1',
          'paint_id': 'P1',
          'count': 5,
          'in_inventory': true,
          'in_whitelist': false,
          'inventory_id': 'I1',
          'wishlist_id': 'W1',
          'paint': {
            'name': 'Red',
            'code': 'R1',
            'set': 'S1',
            'r': 255,
            'g': 0,
            'b': 0,
            'hex': '#FF0000',
            'color': 'url',
            'barcode': '123',
          },
          'brand': {'name': 'BrandName', 'logo_url': 'logo.png'},
          'palette_info': [
            {'id': 'PI1', 'name': 'Pal1', 'created_at': '2025-08-01T12:00:00Z'},
          ],
        },
      ];
      when(
        mockClient.get(
          Uri.parse('$baseUrl/palettes/most-used-paints'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'executed': true, 'data': raw}), 200),
      );

      final result = await service.getMostUsedPaints(token);
      expect(result.length, 1);
      final item = result.first;
      expect(item.brandId, 'B1');
      expect(item.paintId, 'P1');
      expect(item.count, 5);
      expect(item.inInventory, isTrue);
      expect(item.inWhitelist, isFalse);
      expect(item.inventoryId, 'I1');
      expect(item.wishlistId, 'W1');
      expect(item.paint.name, 'Red');
      expect(item.brand.logoUrl, 'logo.png');
      expect(item.paletteInfo.first.id, 'PI1');
    });

    test('throws when executed is false', () async {
      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'executed': false, 'message': 'err'}),
          200,
        ),
      );

      expect(
        () => service.getMostUsedPaints(token),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('err'),
          ),
        ),
      );
    });
  });
}
