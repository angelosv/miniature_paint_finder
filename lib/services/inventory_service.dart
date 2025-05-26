import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/paint_inventory_item.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniature_paint_finder/services/paint_brand_service.dart';
import 'package:miniature_paint_finder/utils/env.dart';

/// A service for managing paint inventory data.
///
/// This service is responsible for:
/// - Loading and saving inventory data
/// - Filtering and sorting inventory items
/// - Managing stock levels and notes
/// - Providing palette association information
///
/// In a real application, this would interact with a database or API.
class InventoryService {
  List<PaintInventoryItem> _inventory = [];
  bool _isInitialized = false;
  final PaintBrandService _brandService = PaintBrandService();
  int _totalPages = 1;

  /// Gets a list of all inventory items.
  /// Returns a copy of the inventory list to prevent external modification.
  List<PaintInventoryItem> get inventory => List.unmodifiable(_inventory);

  /// Gets the total number of pages available.
  int get totalPages => _totalPages;

  /// Checks if the inventory has been initialized.
  bool get isInitialized => _isInitialized;

  /// Loads the inventory data.
  ///
  /// In a real application, this would load data from a local database or remote API.
  /// For this example, it uses sample data with a simulated delay.
  Future<void> loadInventory({
    int limit = 10,
    int page = 1,
    String? searchQuery,
    bool? onlyInStock,
    String? brand,
    String? category,
    int? minStock,
    int? maxStock,
  }) async {
    try {
      final result = await loadInventoryFromApi(
        limit: limit,
        page: page,
        searchQuery: searchQuery,
        onlyInStock: onlyInStock,
        brand: brand,
        category: category,
        minStock: minStock,
        maxStock: maxStock,
      );
      _inventory = result['inventories'] as List<PaintInventoryItem>;
      _totalPages = result['totalPages'] as int;
    } catch (e) {
      rethrow;
    }
  }

  /// Gets unique brands from the API for filtering.
  Future<List<String>> getUniqueBrands() async {
    try {
      final brands = await _brandService.getPaintBrands();
      return brands.map((brand) => brand.name).toList()..sort();
    } catch (e) {
      final brands =
          _inventory.map((item) => item.paint.brand).toSet().toList();
      brands.sort();
      return brands;
    }
  }

  /// Gets unique categories from the inventory for filtering.
  List<String> getUniqueCategories() {
    final categories =
        _inventory.map((item) => item.paint.category).toSet().toList();
    categories.sort();
    return categories;
  }

  /// Gets the maximum stock level in the inventory.
  int getMaxStockLevel() {
    if (_inventory.isEmpty) return 0;
    return _inventory.fold(
      0,
      (max, item) => item.stock > max ? item.stock : max,
    );
  }

  /// Updates the stock level for a paint item.
  ///
  /// Returns true if the update was successful, false otherwise.
  bool updateStock(String paintId, int newStock) {
    if (newStock < 0) return false;

    final index = _inventory.indexWhere((item) => item.paint.id == paintId);
    if (index == -1) return false;

    _inventory[index] = _inventory[index].copyWith(stock: newStock);
    return true;
  }

  /// Updates the stock level for a paint item using the API.
  ///
  /// Returns true if the update was successful, false otherwise.
  Future<bool> updateStockFromApi(String inventoryId, int newStock) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final token = await user.getIdToken();
      if (token == null) return false;

      final url = Uri.parse('${Env.apiBaseUrl}/inventory/$inventoryId');
      final requestBody = {'quantity': newStock};

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Actualiza cantidad y notas de un registro de inventario vía API.
  /// Devuelve true si la actualización fue exitosa, false en caso contrario.
  Future<bool> updateInventoryRecord(
    String inventoryId,
    int quantity,
    String? notes,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final token = await user.getIdToken();
      if (token == null) return false;

      final url = Uri.parse('${Env.apiBaseUrl}/inventory/$inventoryId');
      final body = {'quantity': quantity, if (notes != null) 'notes': notes};

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Updates the notes for a paint item.
  ///
  /// Returns true if the update was successful, false otherwise.
  bool updateNotes(String paintId, String notes) {
    final index = _inventory.indexWhere((item) => item.paint.id == paintId);
    if (index == -1) return false;

    _inventory[index] = _inventory[index].copyWith(notes: notes);
    return true;
  }

  /// Actualiza las notas de un registro de inventario usando la API.
  ///
  /// Returns true si la actualización fue exitosa, false en caso contrario.
  Future<bool> updateNotesFromApi(String inventoryId, String notes) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final token = await user.getIdToken();
      if (token == null) return false;

      final url = Uri.parse('${Env.apiBaseUrl}/inventory/$inventoryId');
      final requestBody = {'notes': notes};

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Adds a new paint to the inventory.
  ///
  /// Returns true if the addition was successful, false if the paint already exists.
  bool addPaintToInventory(Paint paint, {int stock = 1, String notes = ''}) {
    if (_inventory.any((item) => item.paint.id == paint.id)) {
      return false;
    }

    final newItem = PaintInventoryItem(
      id: paint.id,
      paint: paint,
      stock: stock,
      notes: notes,
    );

    _inventory.add(newItem);
    return true;
  }

  /// Removes a paint from the inventory.
  ///
  /// Returns true if the removal was successful, false if the paint wasn't found.
  bool removePaintFromInventory(String paintId) {
    final initialLength = _inventory.length;
    _inventory.removeWhere((item) => item.paint.id == paintId);
    return _inventory.length < initialLength;
  }

  /// Filtra el inventario según los criterios especificados.
  ///
  /// Este método ya no es necesario ya que ahora filtramos desde la API.
  /// Se mantiene por compatibilidad con código existente.
  List<PaintInventoryItem> filterInventory({
    String searchQuery = '',
    bool onlyInStock = false,
    String? brand,
    String? category,
    int minStock = 0,
    int maxStock = 999,
  }) {
    return _inventory;
  }

  /// Sorts inventory items based on the specified column and direction.
  ///
  /// [sortColumn] can be 'name', 'brand', 'category', or 'stock'.
  /// [ascending] determines the sort direction.
  List<PaintInventoryItem> sortInventory(
    List<PaintInventoryItem> items,
    String sortColumn,
    bool ascending,
  ) {
    final sorted = List<PaintInventoryItem>.from(items);

    sorted.sort((a, b) {
      int result;
      switch (sortColumn) {
        case 'name':
          result = a.paint.name.compareTo(b.paint.name);
          break;
        case 'brand':
          result = a.paint.brand.compareTo(b.paint.brand);
          break;
        case 'category':
          result = a.paint.category.compareTo(b.paint.category);
          break;
        case 'stock':
          result = a.stock.compareTo(b.stock);
          break;
        default:
          result = a.paint.name.compareTo(b.paint.name);
      }

      return ascending ? result : -result;
    });

    return sorted;
  }

  /// Gets a list of palette names that include a specific paint.
  ///
  /// In a real app, this would query a database or API.
  /// For this example, it returns simulated data based on the paint ID.
  List<String> getPalettesUsingPaint(String paintId) {
    final List<String> palettes = [];
    final hashCode = paintId.hashCode;

    if (hashCode % 3 == 0) palettes.add('Space Marines');
    if (hashCode % 5 == 0) palettes.add('Imperial Guard');
    if (hashCode % 7 == 0) palettes.add('Chaos Warriors');
    if (hashCode % 11 == 0) palettes.add('Necrons');
    if (hashCode % 13 == 0) palettes.add('Eldar');
    if (hashCode % 17 == 0) palettes.clear();

    return palettes;
  }

  /// Adds a new inventory record using the API.
  ///
  /// Returns true if the addition was successful, false otherwise.
  Future<bool> addInventoryRecord({
    required String brandId,
    required String paintId,
    required int quantity,
    String? notes,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final token = await user.getIdToken();
      if (token == null) return false;

      final url = Uri.parse('${Env.apiBaseUrl}/inventory');
      final requestBody = {
        'brand_id': brandId,
        'paint_id': paintId,
        'quantity': quantity,
        'notes': notes ?? '',
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final paint = Paint(
          id: paintId,
          name: '',
          brand: brandId,
          category: '',
          hex: '',
          set: '',
          code: '',
          r: 0,
          g: 0,
          b: 0,
        );

        return addPaintToInventory(paint, stock: quantity, notes: notes ?? '');
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> addInventoryRecordReturningId({
    required String brandId,
    required String paintId,
    required int quantity,
    String? notes,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final token = await user.getIdToken();

      final url = Uri.parse('${Env.apiBaseUrl}/inventory');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'brand_id': brandId,
          'paint_id': paintId,
          'quantity': quantity,
          'notes': notes ?? '',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['data']?['id']?.toString();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Carga el inventario desde la API con paginación y filtros
  Future<Map<String, dynamic>> loadInventoryFromApi({
    int limit = 10,
    int page = 1,
    String? searchQuery,
    bool? onlyInStock,
    String? brand,
    String? category,
    int? minStock,
    int? maxStock,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'page': page.toString(),
      };

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      if (onlyInStock == true) {
        queryParams['onlyInStock'] = 'true';
      }

      if (brand != null && brand.isNotEmpty) {
        queryParams['brand'] = brand;
      }

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      if (minStock != null) {
        queryParams['minStock'] = minStock.toString();
      }

      if (maxStock != null) {
        queryParams['maxStock'] = maxStock.toString();
      }

      final uri = Uri.parse(
        '${Env.apiBaseUrl}/inventory',
      ).replace(queryParameters: queryParams);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      final token = await user.getIdToken();
      if (token == null) {
        throw Exception('No se pudo obtener el token de Firebase');
      }

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<PaintInventoryItem> inventories = [];
        if (data['inventories'] != null && data['inventories'] is List) {
          inventories =
              (data['inventories'] as List)
                  .map((item) => PaintInventoryItem.fromJson(item))
                  .toList();
        }

        return {
          'inventories': inventories,
          'totalPages': data['totalPages'] ?? 1,
        };
      } else {
        throw Exception(
          'Failed to load inventory: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Elimina un registro del inventario usando la API.
  ///
  /// Returns true si la eliminación fue exitosa, false en caso contrario.
  Future<bool> deleteInventoryRecord(String inventoryId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final token = await user.getIdToken();
      if (token == null) return false;

      final url = Uri.parse('${Env.apiBaseUrl}/inventory/$inventoryId');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
