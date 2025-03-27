import 'package:miniature_paint_finder/data/api_constants.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/repositories/base_repository.dart';
import 'package:miniature_paint_finder/services/api_service.dart';

/// Repositorio para operaciones con paletas de colores
abstract class PaletteRepository extends BaseRepository<Palette> {
  /// Obtiene todas las paletas del usuario actual
  Future<List<Palette>> getUserPalettes();

  /// Añade una pintura a una paleta existente
  Future<bool> addPaintToPalette(
    String paletteId,
    String paintId,
    String colorHex,
  );

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
      final response = await _apiService.get(ApiEndpoints.userPalettes);
      return (response['palettes'] as List)
          .map((json) => Palette.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting palettes from API: $e');
      return SampleData.getPalettes();
    }
  }

  @override
  Future<Palette?> getById(String id) async {
    try {
      final response = await _apiService.get(ApiEndpoints.paletteById(id));
      return Palette.fromJson(response);
    } catch (e) {
      print('Error getting palette by ID from API: $e');
      try {
        return SampleData.getPalettes().firstWhere(
          (palette) => palette.id == id,
        );
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<Palette> create(Palette item) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.userPalettes,
        item.toJson(),
      );
      return Palette.fromJson(response);
    } catch (e) {
      print('Error creating palette in API: $e');
      // Fallback para desarrollo - asignar un ID temporal
      return Palette(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        name: item.name,
        imagePath: item.imagePath,
        colors: item.colors,
        createdAt: DateTime.now(),
        paintSelections: item.paintSelections,
      );
    }
  }

  @override
  Future<Palette> update(Palette item) async {
    try {
      final response = await _apiService.put(
        ApiEndpoints.paletteById(item.id),
        item.toJson(),
      );
      return Palette.fromJson(response);
    } catch (e) {
      print('Error updating palette in API: $e');
      return item;
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      final response = await _apiService.delete(ApiEndpoints.paletteById(id));
      return response?['success'] ?? false;
    } catch (e) {
      print('Error deleting palette from API: $e');
      return false;
    }
  }

  @override
  Future<List<Palette>> getUserPalettes() async {
    // En esta implementación, getUserPalettes es lo mismo que getAll
    // porque ya estamos obteniendo las paletas del usuario autenticado
    return getAll();
  }

  @override
  Future<bool> addPaintToPalette(
    String paletteId,
    String paintId,
    String colorHex,
  ) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.addPaintToPalette(paletteId),
        {'paintId': paintId, 'colorHex': colorHex},
      );
      return response?['success'] ?? false;
    } catch (e) {
      print('Error adding paint to palette in API: $e');
      return false;
    }
  }

  @override
  Future<bool> removePaintFromPalette(String paletteId, String paintId) async {
    try {
      final response = await _apiService.delete(
        '${ApiEndpoints.addPaintToPalette(paletteId)}/$paintId',
      );
      return response?['success'] ?? false;
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
  bool _initialized = false;

  PaletteRepositoryImpl() {
    print('🏭 PaletteRepositoryImpl constructor called');
    // Inicializar inmediatamente
    _initializePalettes();
  }

  void _initializePalettes() {
    print('🛠️ Forcing initialization of sample palettes');
    _palettes = SampleData.getPalettes();
    _initialized = _palettes != null && _palettes!.isNotEmpty;
    print('🛠️ Initialized ${_palettes?.length ?? 0} sample palettes');

    // Debug log the palettes
    if (_palettes != null) {
      for (var i = 0; i < _palettes!.length; i++) {
        print('   📝 Palette ${i + 1}: ${_palettes![i].name}');
      }
    }
  }

  @override
  Future<List<Palette>> getAll() async {
    print('📚 PaletteRepositoryImpl.getAll() called');
    // Simular retardo de API
    await Future.delayed(const Duration(milliseconds: 300));

    if (!_initialized || _palettes == null || _palettes!.isEmpty) {
      print('📚 Palettes not properly initialized, reinitializing');
      _initializePalettes();
    } else {
      print('📚 Using cached palettes (${_palettes!.length})');
    }

    // Ensure we always return a valid list even if initialization failed
    if (!_initialized || _palettes == null || _palettes!.isEmpty) {
      print('⚠️ WARNING: Failed to initialize palettes, fetching directly');
      final directPalettes = SampleData.getPalettes();
      print('⚠️ Direct fetch result: ${directPalettes.length} palettes');
      return directPalettes;
    }

    print('📚 Returning ${_palettes!.length} palettes from getAll()');
    // Devolver una copia para evitar modificaciones accidentales
    return List.from(_palettes!);
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
  Future<List<Palette>> getUserPalettes() async {
    print('👤 PaletteRepositoryImpl.getUserPalettes() called');
    // Para esta implementación de prueba, devolvemos todas las paletas
    final palettes = await getAll();
    print('👤 Returning ${palettes.length} palettes from getUserPalettes()');
    return palettes;
  }

  @override
  Future<bool> addPaintToPalette(
    String paletteId,
    String paintId,
    String colorHex,
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
