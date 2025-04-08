import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/paint_inventory_item.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// Gets a list of all inventory items.
  /// Returns a copy of the inventory list to prevent external modification.
  List<PaintInventoryItem> get inventory => List.unmodifiable(_inventory);

  /// Checks if the inventory has been initialized.
  bool get isInitialized => _isInitialized;

  /// Loads the inventory data.
  ///
  /// In a real application, this would load data from a local database or remote API.
  /// For this example, it uses sample data with a simulated delay.
  Future<void> loadInventory() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final paints = SampleData.getPaints();

    // Create inventory with randomized stock levels
    _inventory =
        paints.map((paint) {
          return PaintInventoryItem(
            paint: paint,
            stock: (paint.id.hashCode % 5), // Random stock between 0 and 4
            notes: '',
          );
        }).toList();

    _isInitialized = true;
  }

  /// Gets unique brands from the inventory for filtering.
  List<String> getUniqueBrands() {
    final brands = _inventory.map((item) => item.paint.brand).toSet().toList();
    brands.sort();
    return brands;
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

  /// Updates the notes for a paint item.
  ///
  /// Returns true if the update was successful, false otherwise.
  bool updateNotes(String paintId, String notes) {
    final index = _inventory.indexWhere((item) => item.paint.id == paintId);
    if (index == -1) return false;

    _inventory[index] = _inventory[index].copyWith(notes: notes);
    return true;
  }

  /// Adds a new paint to the inventory.
  ///
  /// Returns true if the addition was successful, false if the paint already exists.
  bool addPaintToInventory(Paint paint, {int stock = 1, String notes = ''}) {
    // Check if the paint already exists in inventory
    if (_inventory.any((item) => item.paint.id == paint.id)) {
      return false;
    }

    final newItem = PaintInventoryItem(
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

  /// Filters inventory items based on various criteria.
  ///
  /// All filter parameters are optional. If not provided, that filter criterion is ignored.
  List<PaintInventoryItem> filterInventory({
    String? searchQuery,
    bool? onlyInStock,
    String? brand,
    String? category,
    int? minStock,
    int? maxStock,
  }) {
    return _inventory.where((item) {
      // Search query filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final nameMatches = item.paint.name.toLowerCase().contains(query);
        final brandMatches = item.paint.brand.toLowerCase().contains(query);
        final categoryMatches = item.paint.category.toLowerCase().contains(
          query,
        );

        if (!(nameMatches || brandMatches || categoryMatches)) {
          return false;
        }
      }

      // Stock filter
      if (onlyInStock == true && item.stock <= 0) {
        return false;
      }

      if (minStock != null && item.stock < minStock) {
        return false;
      }

      if (maxStock != null && item.stock > maxStock) {
        return false;
      }

      // Brand filter
      if (brand != null && item.paint.brand != brand) {
        return false;
      }

      // Category filter
      if (category != null && item.paint.category != category) {
        return false;
      }

      return true;
    }).toList();
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
    // Generate deterministic mock data based on the paintId
    final List<String> palettes = [];
    final hashCode = paintId.hashCode;

    // Some arbitrary logic to create different palette lists for different paints
    if (hashCode % 3 == 0) palettes.add('Space Marines');
    if (hashCode % 5 == 0) palettes.add('Imperial Guard');
    if (hashCode % 7 == 0) palettes.add('Chaos Warriors');
    if (hashCode % 11 == 0) palettes.add('Necrons');
    if (hashCode % 13 == 0) palettes.add('Eldar');

    // Ensure some paints have no palettes
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
      // Obtener el token de Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Error: No hay usuario autenticado');
        return false;
      }

      final token = await user.getIdToken();
      if (token == null) {
        print('Error: No se pudo obtener el token de Firebase');
        return false;
      }

      final response = await http.post(
        Uri.parse('https://paints-api.reachu.io/api/inventory'),
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
        // Actualizar el inventario local después de una adición exitosa
        final paint = Paint(
          id: paintId,
          name: '', // Estos campos se actualizarán cuando se cargue el inventario
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
      
      print('Error en la respuesta del servidor: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('Error adding inventory record: $e');
      return false;
    }
  }
}
