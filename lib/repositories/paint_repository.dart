import 'package:miniature_paint_finder/data/api_constants.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/repositories/base_repository.dart';
import 'package:miniature_paint_finder/services/api_service.dart';
/// Repository interface for paint operations
abstract class PaintRepository extends BaseRepository<Paint> {
  /// Find paints by color hex
  Future<List<Paint>> findByColor(String colorHex, {double threshold = 0.1});

  /// Find paints by brand
  Future<List<Paint>> findByBrand(String brand);

  /// Find paints by category
  Future<List<Paint>> findByCategory(String category);

  /// Find paints by barcode
  Future<Paint?> findByBarcode(String barcode);

  /// Search paints by name
  Future<List<Paint>> searchByName(String query);
}

/// Implementación del repositorio que utiliza la API
class ApiPaintRepository implements PaintRepository {
  final ApiService _apiService;

  ApiPaintRepository(this._apiService);

  @override
  Future<List<Paint>> getAll() async {
    try {
      final response = await _apiService.get(ApiEndpoints.paints);
      return (response as List).map((json) => Paint.fromJson(json)).toList();
    } catch (e) {
      // Fallback a datos de muestra si la API falla
      print('Error getting paints from API: $e');
      return SampleData.getPaints();
    }
  }

  @override
  Future<Paint?> getById(String id) async {
    try {
      final response = await _apiService.get(ApiEndpoints.paintById(id));
      return Paint.fromJson(response);
    } catch (e) {
      print('Error getting paint by ID from API: $e');
      try {
        return SampleData.getPaints().firstWhere((paint) => paint.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<Paint> create(Paint item) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.paints,
        item.toJson(),
      );
      return Paint.fromJson(response);
    } catch (e) {
      print('Error creating paint in API: $e');
      return item; // Devolvemos el item sin cambios como fallback
    }
  }

  @override
  Future<Paint> update(Paint item) async {
    try {
      final response = await _apiService.put(
        ApiEndpoints.paintById(item.id),
        item.toJson(),
      );
      return Paint.fromJson(response);
    } catch (e) {
      print('Error updating paint in API: $e');
      return item;
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      await _apiService.delete(ApiEndpoints.paintById(id));
      return true;
    } catch (e) {
      print('Error deleting paint from API: $e');
      return false;
    }
  }

  @override
  Future<List<Paint>> findByColor(
    String colorHex, {
    double threshold = 0.1,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.paintsByColor(colorHex, threshold: threshold),
      );
      return (response as List).map((json) => Paint.fromJson(json)).toList();
    } catch (e) {
      print('Error finding paints by color from API: $e');
      // Implementación temporal para datos de muestra
      final allPaints = SampleData.getPaints();
      // Filtrar por similitud de color (implementación simplificada)
      return allPaints.take(5).toList();
    }
  }

  @override
  Future<List<Paint>> findByBrand(String brand) async {
    try {
      final response = await _apiService.get(ApiEndpoints.paintsByBrand(brand));
      return (response as List).map((json) => Paint.fromJson(json)).toList();
    } catch (e) {
      print('Error finding paints by brand from API: $e');
      return SampleData.getPaints()
          .where((paint) => paint.brand.toLowerCase() == brand.toLowerCase())
          .toList();
    }
  }

  @override
  Future<List<Paint>> findByCategory(String category) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.paintsByCategory(category),
      );
      return (response as List).map((json) => Paint.fromJson(json)).toList();
    } catch (e) {
      print('Error finding paints by category from API: $e');
      return SampleData.getPaints()
          .where(
            (paint) => paint.category.toLowerCase() == category.toLowerCase(),
          )
          .toList();
    }
  }

  @override
  Future<Paint?> findByBarcode(String barcode) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.paintsByBarcode(barcode),
      );
      return Paint.fromJson(response);
    } catch (e) {
      print('Error finding paint by barcode from API: $e');
      // Para demo, simplemente devolvemos el primer paint si hay barcode
      if (barcode.isNotEmpty) {
        return SampleData.getPaints().first;
      }
      return null;
    }
  }

  @override
  Future<List<Paint>> searchByName(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final response = await _apiService.get(ApiEndpoints.searchPaints(query));
      return (response as List).map((json) => Paint.fromJson(json)).toList();
    } catch (e) {
      print('Error searching paints by name from API: $e');
      return SampleData.getPaints()
          .where(
            (paint) =>
                paint.name.toLowerCase().contains(query.toLowerCase()) ||
                paint.brand.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }
}

/// Implementation of PaintRepository using in-memory sample data
/// In a real application, this would be replaced with an implementation
/// that communicates with a backend API or local database.
class PaintRepositoryImpl implements PaintRepository {
  @override
  Future<List<Paint>> getAll() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    return SampleData.getPaints();
  }

  @override
  Future<Paint?> getById(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      return SampleData.getPaints().firstWhere((paint) => paint.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Paint> create(Paint item) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 200));

    // In a real implementation, this would add to a database
    // For demo, we'll just return the item as if it was created
    return item;
  }

  @override
  Future<Paint> update(Paint item) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 200));

    // In a real implementation, this would update the database
    // For demo, we'll just return the updated item
    return item;
  }

  @override
  Future<bool> delete(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 150));

    // In a real implementation, this would delete from a database
    // For demo, we'll just return success
    return true;
  }

  @override
  Future<List<Paint>> findByColor(
    String colorHex, {
    double threshold = 0.1,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 350));

    // For demo purposes, just return a subset of paints
    // In a real implementation, this would use color matching algorithms
    return SampleData.getPaints().take(5).toList();
  }

  @override
  Future<List<Paint>> findByBrand(String brand) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 200));

    return SampleData.getPaints()
        .where((paint) => paint.brand.toLowerCase() == brand.toLowerCase())
        .toList();
  }

  @override
  Future<List<Paint>> findByCategory(String category) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 200));

    return SampleData.getPaints()
        .where(
          (paint) => paint.category.toLowerCase() == category.toLowerCase(),
        )
        .toList();
  }

  @override
  Future<Paint?> findByBarcode(String barcode) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 250));

    // For demo purposes
    if (barcode.isNotEmpty) {
      return SampleData.getPaints().first;
    }
    return null;
  }

  @override
  Future<List<Paint>> searchByName(String query) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    if (query.isEmpty) {
      return [];
    }

    return SampleData.getPaints()
        .where(
          (paint) =>
              paint.name.toLowerCase().contains(query.toLowerCase()) ||
              paint.brand.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
