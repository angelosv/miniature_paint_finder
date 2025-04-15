import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/data/api_constants.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/models/api_palette.dart';
import 'package:miniature_paint_finder/repositories/base_repository.dart';
import 'package:miniature_paint_finder/services/api_service.dart';

class ApiImageColorPick {
  final String imageId;
  final int index;
  final String hexColor;
  final int r;
  final int g;
  final int b;
  final String xCoord;
  final String yCoord;
  final DateTime createdAt;
  final String userId;
  final String imagePath;

  const ApiImageColorPick({
    required this.imageId,
    required this.index,
    required this.hexColor,
    required this.r,
    required this.g,
    required this.b,
    required this.xCoord,
    required this.yCoord,
    required this.createdAt,
    required this.userId,
    required this.imagePath,
  });

  factory ApiImageColorPick.fromJson(Map<String, dynamic> json) {
    return ApiImageColorPick(
      imageId: json['image_id'] as String,
      index: json['index'] as int,
      hexColor: json['hex_color'] as String,
      r: json['r'] as int,
      g: json['g'] as int,
      b: json['b'] as int,
      xCoord: json['x_coord'] as String,
      yCoord: json['y_coord'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
      imagePath: json['image_path'] as String,
    );
  }

  @override
  String toString() {
    return 'ApiImageColorPick(imageId: $imageId, index: $index, hexColor: $hexColor, r: $r, g: $g, b: $b)';
  }
}

/// Repositorio para operaciones con paletas de colores
abstract class PaletteRepository extends BaseRepository<Palette> {
  /// Obtiene todas las paletas del usuario actual
  Future<Map<String, dynamic>> getUserPalettes({int page = 1, int limit = 10});

  /// Añade una pintura a una paleta existente
  Future<bool> addPaintToPalette(String paletteId, String paintId, String hex);

  /// Elimina una pintura de una paleta existente
  Future<bool> removePaintFromPalette(String paletteId, String paintId);
}

/// Implementación del repositorio de paletas usando API
class ApiPaletteRepository implements PaletteRepository {
  final ApiService _apiService;

  ApiPaletteRepository(this._apiService);

  @override
  Future<List<Palette>> getAll() async {
    try {
      print('🎨 Using endpoint Palettes getAll: ${ApiEndpoints.palettes}');
      final response = await _apiService.get(ApiEndpoints.palettes);
      final data = response['data'];
      final palettes =
          (data['palettes'] as List)
              .map((json) => ApiPalette.fromJson(json))
              .toList();

      return palettes
          .map((apiPalette) => _convertApiPaletteToPalette(apiPalette))
          .toList();
    } catch (e) {
      print('Error getting all palettes from API: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getUserPalettes({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print(
        '🎨 ApiPaletteRepository.getUserPalettes() called with page: $page, limit: $limit',
      );
      print(
        '🎨 Using endpoint: ${ApiEndpoints.userPalettes}?page=$page&limit=$limit',
      );

      final response = await _apiService.get(
        '${ApiEndpoints.userPalettes}?page=$page&limit=$limit',
      );

      print('🎨 API Response status: ${response['executed']}');
      print('🎨 API Response message: ${response['message']}');
      print('🎨 API Response data: ${response['data']}');

      final data = response['data'];
      print('🎨 Data from response: ${data.toString()}');

      // Devolver los datos de paginación junto con las paletas
      return {
        'currentPage': int.parse(data['currentPage'].toString()),
        'totalPages': int.parse(data['totalPages'].toString()),
        'totalPalettes': int.parse(data['totalPalettes'].toString()),
        'limit': int.parse(data['limit'].toString()),
        'palettes':
            (data['palettes'] as List)
                .map((json) => ApiPalette.fromJson(json))
                .map((apiPalette) => _convertApiPaletteToPalette(apiPalette))
                .toList(),
      };
    } catch (e) {
      print('❌ Error getting user palettes from API: $e');
      return {
        'currentPage': 1,
        'totalPages': 1,
        'totalPalettes': 0,
        'limit': limit,
        'palettes': <Palette>[],
      };
    }
  }

  Palette _convertApiPaletteToPalette(ApiPalette apiPalette) {
    print('🎨 Converting API Palette to local Palette');
    print('🎨 API Palette data:');
    print('  - ID: ${apiPalette.id}');
    print('  - Name: ${apiPalette.name}');
    print('  - Image: ${apiPalette.image}');
    print('  - Created At: ${apiPalette.createdAt}');
    print('  - Number of paints: ${apiPalette.palettesPaints.length}');
    print('  - Total Paints: ${apiPalette.totalPaints}');
    print('  - Created At Text: ${apiPalette.createdAtText}');

    final colors = apiPalette.palettesPaints.map((paint) {
      if (paint.paint != null) {
        print('  🎨 Paint found:');
        print('    - Name: ${paint.paint!.name}');
        print('    - Hex: ${paint.paint!.hex}');
        print('    - RGB: (${paint.paint!.r}, ${paint.paint!.g}, ${paint.paint!.b})');
        return Color.fromRGBO(
          paint.paint!.r,
          paint.paint!.g,
          paint.paint!.b,
          1,
        );
      } else if (paint.imageColorPicks != null) {
        print('  🎨 Using color from image pick:');
        print('    - Image Color Pick: ${paint.imageColorPicks.toString()}');
        if (paint.imageColorPicks!.r == null || 
            paint.imageColorPicks!.g == null || 
            paint.imageColorPicks!.b == null) {
          print('    ⚠️ Warning: RGB values are null, using default color');
          return Colors.grey;
        }
        return Color.fromRGBO(
          paint.imageColorPicks!.r,
          paint.imageColorPicks!.g,
          paint.imageColorPicks!.b,
          1,
        );
      }
      print('  ⚠️ No paint or color data available');
      return Colors.grey; // Color por defecto si no hay pintura
    }).toList();

    final convertedPalette = Palette(
      id: apiPalette.id,
      name: apiPalette.name,
      imagePath: apiPalette.image ?? 'assets/images/placeholder.jpeg',
      colors: colors,
      createdAt: apiPalette.createdAt,
      totalPaints: apiPalette.totalPaints,
      createdAtText: apiPalette.createdAtText,
      paintSelections: apiPalette.palettesPaints.map((paint) {
        if (paint.paint != null) {
          return PaintSelection(
            paintId: paint.paint!.code,
            paintName: paint.paint!.name,
            paintBrand: paint.paint!.set,
            brandAvatar: paint.paint!.set[0],
            matchPercentage: 100,
            colorHex: paint.paint!.hex,
            paintColorHex: paint.paint!.hex,
            paintBrandId: paint.brandId,
            paintBarcode: paint.paint?.barcode ?? '',
            paintCode: paint.paint?.code ?? '',
          );
        } else if (paint.imageColorPicks != null) {
          return PaintSelection(
            paintId: paint.paintId,
            paintName: 'Color from image',
            paintBrand: 'Image',
            brandAvatar: 'I',
            matchPercentage: 100,
            colorHex: paint.imageColorPicks!.hexColor,
            paintColorHex: paint.imageColorPicks!.hexColor,
            paintBrandId: paint.brandId,
            paintBarcode: paint.paint?.barcode ?? '',
            paintCode: paint.paint?.code ?? '',
          );
        }
        return null;
      }).whereType<PaintSelection>().toList(),
    );

    print('🎨 Converted Palette:');
    print('  - ID: ${convertedPalette.id}');
    print('  - Name: ${convertedPalette.name}');
    print('  - Image Path: ${convertedPalette.imagePath}');
    print('  - Number of colors: ${convertedPalette.colors.length}');
    print('  - Number of paint selections: ${convertedPalette.paintSelections?.length ?? 0}');
    print('  - Total Paints: ${convertedPalette.totalPaints}');
    print('  - Created At Text: ${convertedPalette.createdAtText}');

    return convertedPalette;
  }

  @override
  Future<Palette?> getById(String id) async {
    try {
      final response = await _apiService.get(ApiEndpoints.paletteById(id));
      final apiPalette = ApiPalette.fromJson(response);
      return _convertApiPaletteToPalette(apiPalette);
    } catch (e) {
      print('Error getting palette by ID from API: $e');
      return null;
    }
  }

  @override
  Future<Palette> create(Palette item) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.userPalettes,
        item.toJson(),
      );
      final apiPalette = ApiPalette.fromJson(response);
      return _convertApiPaletteToPalette(apiPalette);
    } catch (e) {
      print('Error creating palette in API: $e');
      return item;
    }
  }

  @override
  Future<Palette> update(Palette item) async {
    try {
      final response = await _apiService.put(
        ApiEndpoints.paletteById(item.id),
        item.toJson(),
      );
      final apiPalette = ApiPalette.fromJson(response);
      return _convertApiPaletteToPalette(apiPalette);
    } catch (e) {
      print('Error updating palette in API: $e');
      return item;
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      final response = await _apiService.delete(ApiEndpoints.paletteById(id));
      return response['executed'] == true;
    } catch (e) {
      print('Error deleting palette from API: $e');
      return false;
    }
  }

  @override
  Future<bool> addPaintToPalette(
    String paletteId,
    String paintId,
    String hex,
  ) async {
    try {
      await _apiService.post('${ApiEndpoints.paletteById(paletteId)}/paints', {
        'paint_id': paintId,
        'color_hex': hex,
      });
      return true;
    } catch (e) {
      print('Error adding paint to palette in API: $e');
      return false;
    }
  }

  @override
  Future<bool> removePaintFromPalette(String paletteId, String paintId) async {
    try {
      await _apiService.delete(
        '${ApiEndpoints.paletteById(paletteId)}/paints/$paintId',
      );
      return true;
    } catch (e) {
      print('Error removing paint from palette in API: $e');
      return false;
    }
  }
}

/// Implementación del repositorio de paletas usando datos de muestra
/// Esta implementación es para desarrollo y testing sin backend
class PaletteRepositoryImpl implements PaletteRepository {
  List<Palette>? _palettes;

  @override
  Future<List<Palette>> getAll() async {
    print('📚 PaletteRepositoryImpl.getAll() called');
    // Simular retardo de API
    await Future.delayed(const Duration(milliseconds: 300));

    if (_palettes == null) {
      print('📚 Initializing sample palettes from SampleData.getPalettes()');
      _palettes = SampleData.getPalettes();
      print('📚 Got ${_palettes!.length} sample palettes');
    } else {
      print('📚 Using cached palettes (${_palettes!.length})');
    }

    return _palettes!;
  }

  @override
  Future<Palette?> getById(String id) async {
    // Simular retardo de API
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _palettes!.firstWhere((palette) => palette.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Palette> create(Palette item) async {
    // Simular retardo de API
    await Future.delayed(const Duration(milliseconds: 200));

    // Crear una copia con un nuevo ID
    final newPalette = Palette(
      id: 'palette-${_palettes!.length + 1}',
      name: item.name,
      imagePath: item.imagePath,
      colors: item.colors,
      createdAt: DateTime.now(),
      paintSelections: item.paintSelections,
    );

    _palettes!.add(newPalette);
    return newPalette;
  }

  @override
  Future<Palette> update(Palette item) async {
    // Simular retardo de API
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _palettes!.indexWhere((palette) => palette.id == item.id);
    if (index != -1) {
      _palettes![index] = item;
    }

    return item;
  }

  @override
  Future<bool> delete(String id) async {
    // Simular retardo de API
    await Future.delayed(const Duration(milliseconds: 150));

    final initialLength = _palettes!.length;
    _palettes!.removeWhere((palette) => palette.id == id);
    return _palettes!.length < initialLength;
  }

  @override
  Future<Map<String, dynamic>> getUserPalettes({
    int page = 1,
    int limit = 10,
  }) async {
    // Para esta implementación de prueba, devolvemos todas las paletas
    final palettes = await getAll();

    return {
      'currentPage': page,
      'totalPages': (palettes.length / limit).ceil(),
      'totalPalettes': palettes.length,
      'limit': limit,
      'palettes': palettes,
    };
  }

  @override
  Future<bool> addPaintToPalette(
    String paletteId,
    String paintId,
    String hex,
  ) async {
    // Simular retardo de API
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _palettes!.indexWhere((palette) => palette.id == paletteId);
    if (index != -1) {
      // En una implementación real, aquí añadiríamos la pintura a la paleta
      return true;
    }
    return false;
  }

  @override
  Future<bool> removePaintFromPalette(String paletteId, String paintId) async {
    // Simular retardo de API
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _palettes!.indexWhere((palette) => palette.id == paletteId);
    if (index != -1) {
      // En una implementación real, aquí eliminaríamos la pintura de la paleta
      return true;
    }
    return false;
  }
}
