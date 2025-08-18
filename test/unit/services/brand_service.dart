import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:miniature_paint_finder/services/brand_service.dart';
import 'brand_service.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;
  late BrandService service;
  const testUrl = 'https://test.api';

  setUp(() {
    // Reset mock preferences
    SharedPreferences.setMockInitialValues({});
    mockClient = MockClient();
    service = BrandService(baseUrl: testUrl, client: mockClient);
  });

  group('API Loading', () {
    test('loadBrands succeeds on valid API response', () async {
      final apiData = [
        {'id': 'X1', 'name': 'BrandX'},
        {'id': 'Y2', 'name': 'BrandY'},
      ];
      when(
        mockClient.get(
          Uri.parse('$testUrl/brand'),
          headers: {'Content-Type': 'application/json'},
        ),
      ).thenAnswer((_) async => http.Response(json.encode(apiData), 200));

      final result = await service.loadBrands();
      expect(result, isTrue);
      expect(service.isLoaded, isTrue);
      expect(service.getBrandId('BrandX'), equals('X1'));
      expect(service.getBrandId('brandy'), equals('Y2'));
      expect(service.isOfficialBrandId('X1'), isTrue);
      expect(service.getBrandName('Y2'), equals('BrandY'));
      expect(service.getAllBrandIds(), containsAll(['X1', 'Y2']));
      expect(
        service.getAllBrands(),
        containsAll([
          {'id': 'X1', 'name': 'BrandX'},
          {'id': 'Y2', 'name': 'BrandY'},
        ]),
      );
    });

    test('loadBrands returns false on HTTP error', () async {
      when(
        mockClient.get(
          Uri.parse('$testUrl/brand'),
          headers: {'Content-Type': 'application/json'},
        ),
      ).thenAnswer((_) async => http.Response('Error', 500));

      final result = await service.loadBrands();
      expect(result, isFalse);
      // Cannot reliably assert isLoaded here due to singleton state
    });
  });

  group('Cache Loading', () {
    test('loadBrands loads from valid cache', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final cacheMap = {
        'timestamp': now,
        'brands': {'cache': 'C1'},
        'brand_names': {'C1': 'CacheBrand'},
        'brand_logos': {'cache': 'http://logo.png'},
      };
      SharedPreferences.setMockInitialValues({
        'official_brands_data': json.encode(cacheMap),
      });
      // Recreate service after setting cache
      service = BrandService(baseUrl: testUrl, client: mockClient);

      final result = await service.loadBrands();
      expect(result, isTrue);
      expect(service.isLoaded, isTrue);
      expect(service.getBrandId('cache'), equals('C1'));
      expect(service.getBrandName('C1'), equals('CacheBrand'));
    });

    test('loadBrands ignores expired cache and uses API', () async {
      final past =
          DateTime.now()
              .subtract(const Duration(hours: 25))
              .millisecondsSinceEpoch;
      final cacheMap = {
        'timestamp': past,
        'brands': {'old': 'O1'},
        'brand_names': {'O1': 'OldBrand'},
      };
      SharedPreferences.setMockInitialValues({
        'official_brands_data': json.encode(cacheMap),
      });

      final apiData = [
        {'id': 'N1', 'name': 'NewBrand'},
      ];
      when(
        mockClient.get(
          Uri.parse('$testUrl/brand'),
          headers: {'Content-Type': 'application/json'},
        ),
      ).thenAnswer((_) async => http.Response(json.encode(apiData), 200));

      service = BrandService(baseUrl: testUrl, client: mockClient);
      final result = await service.loadBrands();
      expect(result, isTrue);
      expect(service.getBrandId('newbrand'), equals('N1'));
      expect(service.getBrandId('old'), isNull);
    });
  });

  group('Default Logos', () {
    test('getLogoUrl returns default logo', () async {
      await service.initialize();
      expect(
        service.getLogoUrl('Army_Painter'),
        equals('https://i.imgur.com/OuMPZQh.png'),
      );
      expect(
        service.getLogoUrl('army painter'),
        equals('https://i.imgur.com/OuMPZQh.png'),
      );
    });
  });
}
