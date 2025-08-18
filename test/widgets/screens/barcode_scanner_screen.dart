import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:miniature_paint_finder/services/color_search_service.dart';
import 'package:miniature_paint_finder/services/palette_service.dart';

import 'barcode_scanner_screen.mocks.dart';

@GenerateMocks([PaletteService])
void main() {
  late MockPaletteService mockPalette;
  late ColorSearchService service;
  const token = 'fake-token';
  const name = 'MyPalette';
  const imagePath = '/tmp/img.png';

  final paints = [
    {'id': 'P1', 'brand_id': 'B1', 'hex': '#FF0000'},
    {'id': 'P2', 'brand_id': 'B2', 'hex': '#00FF00'},
  ];

  setUp(() {
    mockPalette = MockPaletteService();
    service = ColorSearchService(paletteService: mockPalette);
  });

  group('saveColorSearch', () {
    test('happy path completes without error', () async {
      when(
        mockPalette.uploadImage(imagePath, token),
      ).thenAnswer((_) async => {'id': 'IMG1'});

      final picks = [
        {'id': 'PK1'},
        {'id': 'PK2'},
      ];
      when(
        mockPalette.getImagePicks('IMG1', token, any),
      ).thenAnswer((_) async => picks);

      when(
        mockPalette.createPalette(name, token),
      ).thenAnswer((_) async => {'id': 'PAL1'});

      when(
        mockPalette.addPaintsToPalette('PAL1', any, token),
      ).thenAnswer((_) async => null);

      // Should not throw
      await service.saveColorSearch(
        token: token,
        name: name,
        paints: paints,
        imagePath: imagePath,
      );

      verify(mockPalette.uploadImage(imagePath, token)).called(1);
      verify(mockPalette.getImagePicks('IMG1', token, any)).called(1);
      verify(mockPalette.createPalette(name, token)).called(1);
      verify(mockPalette.addPaintsToPalette('PAL1', any, token)).called(1);
    });
  });
}
