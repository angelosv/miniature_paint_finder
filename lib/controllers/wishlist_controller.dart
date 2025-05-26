import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Controlador para manejar la lógica de la pantalla de wishlist
class WishlistController extends ChangeNotifier {
  /// Servicio para acceder a datos de pinturas
  final PaintService _paintService;

  /// Lista de elementos en la wishlist
  List<Map<String, dynamic>> _wishlistItems = [];

  /// Lista filtrada de elementos en la wishlist
  List<Map<String, dynamic>> _filteredItems = [];

  /// Estados de la carga
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  // Filtros
  String _searchQuery = '';
  String? _selectedBrand;
  String? _selectedPalette;
  int? _selectedPriority;

  // Ordenamiento
  String _sortBy =
      'date'; // Valores posibles: 'date', 'name', 'brand', 'priority'
  bool _sortAscending = false; // Por defecto, los más recientes primero

  /// Constructor que recibe el servicio
  WishlistController(this._paintService);

  /// Getters para acceder a los datos desde la UI
  List<Map<String, dynamic>> get wishlistItems => _filteredItems;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _filteredItems.isEmpty;

  // Getters para filtros y ordenamiento
  String get searchQuery => _searchQuery;
  String? get selectedBrand => _selectedBrand;
  String? get selectedPalette => _selectedPalette;
  int? get selectedPriority => _selectedPriority;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Lista de marcas disponibles
  List<String> getAvailableBrands() {
    final brands =
        _wishlistItems
            .map((item) => (item['paint'] as Paint).brand)
            .toSet()
            .toList();
    brands.sort();
    return brands;
  }

  // Lista de paletas disponibles
  List<String> getAvailablePalettes() {
    final Set<String> paletteNames = {};

    for (var item in _wishlistItems) {
      final paint = item['paint'] as Paint;
      final palettes = _paintService.getPalettesContainingPaint(paint.id);
      for (var palette in palettes) {
        paletteNames.add(palette.name);
      }
    }

    final result = paletteNames.toList();
    result.sort();
    return result;
  }

  // Lista de niveles de prioridad disponibles
  List<int> getAvailablePriorities() {
    final priorities =
        _wishlistItems
            .map((item) => item['priority'] as int?)
            .where((priority) => priority != null && priority > 0)
            .toSet()
            .toList();
    priorities.sort();
    return priorities.cast<int>();
  }

  /// Cargar la wishlist desde la API
  Future<void> loadWishlist() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      String token = "token"; // Fallback token for testing
      bool usingFallbackToken = true;

      // Get Firebase token if available
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final idToken = await user.getIdToken();
          if (idToken != null) {
            token = idToken;
            usingFallbackToken = false;
          }
        }
      } catch (e) {
        // Continue with fallback token
      }

      // Call the service to get wishlist items
      final wishlistItems = await _paintService.getWishlistPaints(token);

      _wishlistItems = wishlistItems;
      _applyFiltersAndSort(); // Aplicar filtros y ordenamiento
    } catch (e, stackTrace) {
      _hasError = true;
      _errorMessage = 'Error al cargar wishlist: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Aplicar filtros y ordenamiento
  void _applyFiltersAndSort() {
    // Aplicar filtros
    _filteredItems =
        _wishlistItems.where((item) {
          final paint = item['paint'] as Paint;
          final int priority = item['priority'] as int? ?? 0;

          // Filtrar por búsqueda de texto
          if (_searchQuery.isNotEmpty) {
            final String name = paint.name.toLowerCase();
            final String brand = paint.brand.toLowerCase();
            final String code = paint.code.toLowerCase();
            final String query = _searchQuery.toLowerCase();

            if (!name.contains(query) &&
                !brand.contains(query) &&
                !code.contains(query)) {
              return false;
            }
          }

          // Filtrar por marca
          if (_selectedBrand != null && paint.brand != _selectedBrand) {
            return false;
          }

          // Filtrar por prioridad
          if (_selectedPriority != null && priority != _selectedPriority) {
            return false;
          }

          // Filtrar por paleta
          if (_selectedPalette != null) {
            final palettes = _paintService.getPalettesContainingPaint(paint.id);
            if (!palettes.any((palette) => palette.name == _selectedPalette)) {
              return false;
            }
          }

          return true;
        }).toList();

    // Aplicar ordenamiento
    _filteredItems.sort((a, b) {
      final paintA = a['paint'] as Paint;
      final paintB = b['paint'] as Paint;
      final dateA = a['addedAt'] as DateTime;
      final dateB = b['addedAt'] as DateTime;
      final priorityA = a['priority'] as int? ?? 0;
      final priorityB = b['priority'] as int? ?? 0;

      int result = 0;

      switch (_sortBy) {
        case 'date':
          result = dateA.compareTo(dateB);
          break;
        case 'name':
          result = paintA.name.compareTo(paintB.name);
          break;
        case 'brand':
          result = paintA.brand.compareTo(paintB.brand);
          break;
        case 'priority':
          result = priorityA.compareTo(priorityB);
          break;
      }

      return _sortAscending ? result : -result;
    });
  }

  /// Establecer el filtro de búsqueda
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Establecer el filtro de marca
  void setBrandFilter(String? brand) {
    _selectedBrand = brand;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Establecer el filtro de paleta
  void setPaletteFilter(String? palette) {
    _selectedPalette = palette;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Establecer el filtro de prioridad
  void setPriorityFilter(int? priority) {
    _selectedPriority = priority;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Establecer el ordenamiento
  void setSorting(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Limpiar todos los filtros
  void clearFilters() {
    _searchQuery = '';
    _selectedBrand = null;
    _selectedPalette = null;
    _selectedPriority = null;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Eliminar un elemento de la wishlist
  Future<bool> removeFromWishlist(String paintId, String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      String token = "token"; // Fallback token for testing
      bool usingFallbackToken = true;

      // Get Firebase token if available
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final idToken = await user.getIdToken();
          if (idToken != null) {
            token = idToken;
            usingFallbackToken = false;
          }
        }
      } catch (e) {
        // Continue with fallback token
      }

      final result = await _paintService.removeFromWishlist(paintId, id, token);

      if (result) {
        // Actualizar la lista local
        _wishlistItems.removeWhere((item) => item['id'] == id);
        _applyFiltersAndSort(); // Actualizar la lista filtrada
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Error al eliminar de wishlist: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualizar la prioridad de un elemento en la wishlist
  Future<bool> updatePriority(
    String paintId,
    String id,
    bool isPriority, [
    int priorityLevel = 0,
  ]) async {
    try {
      String token = "token"; // Fallback token for testing
      bool usingFallbackToken = true;

      // Get Firebase token if available
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final idToken = await user.getIdToken();
          if (idToken != null) {
            token = idToken;
            usingFallbackToken = false;
          }
        }
      } catch (e) {
        // Continue with fallback token
      }

      final result = await _paintService.updateWishlistPriority(
        paintId,
        id,
        isPriority,
        token,
        priorityLevel,
      );

      if (result) {
        // Actualizar el elemento en la lista local
        final index = _wishlistItems.indexWhere((item) => item['id'] == id);
        if (index != -1) {
          _wishlistItems[index]['isPriority'] =
              priorityLevel >= 1 && priorityLevel <= 5;

          // Store the actual priority level too
          if (priorityLevel > 0) {
            _wishlistItems[index]['priority'] = priorityLevel;
          }
          _applyFiltersAndSort(); // Actualizar la lista filtrada
          notifyListeners();
        }

        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Añadir una pintura a la wishlist
  Future<bool> addToWishlist(Paint paint, bool isPriority) async {
    try {
      if (paint == null) {
        return false;
      }

      // Call the service method
      final result = await _paintService.addToWishlist(paint, isPriority);

      if (result) {
        // Try to reload wishlist but handle errors
        try {
          await loadWishlist(); // Recargar la lista completa para obtener el ID generado
        } catch (reloadError) {
          // Continue with success flow even if reload fails
        }

        return true;
      } else {
        return false;
      }
    } catch (e, stackTrace) {
      return false;
    }
  }
}
