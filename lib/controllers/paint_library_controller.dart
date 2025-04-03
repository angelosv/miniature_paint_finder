import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/repositories/paint_repository.dart';

/// Controlador para manejar la lógica de la pantalla de biblioteca de pinturas
class PaintLibraryController extends ChangeNotifier {
  /// Repositorio para acceder a datos de pinturas
  final PaintRepository _paintRepository;

  /// Lista completa de pinturas cargadas
  List<Paint> _allPaints = [];

  /// Lista de pinturas filtrada
  List<Paint> _filteredPaints = [];

  /// Conjunto de IDs de pinturas en la lista de deseos
  final Set<String> _wishlist = {};

  /// Estados de la carga
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  /// Filtros actuales
  String _searchQuery = '';
  String _selectedBrand = 'All';
  String _selectedCategory = 'All';
  Color? _selectedColor;

  /// Configuración de paginación
  int _currentPage = 1;
  int _pageSize = 25;

  /// Constructor que recibe el repositorio
  PaintLibraryController(this._paintRepository);

  /// Getters para acceder a los datos desde la UI
  List<Paint> get allPaints => _allPaints;
  List<Paint> get filteredPaints => _filteredPaints;
  Set<String> get wishlist => _wishlist;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedBrand => _selectedBrand;
  String get selectedCategory => _selectedCategory;
  Color? get selectedColor => _selectedColor;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;

  /// Lista de pinturas paginadas para la UI
  List<Paint> get paginatedPaints {
    final startIndex = (currentPage - 1) * pageSize;
    final endIndex = currentPage * pageSize;

    if (startIndex >= _filteredPaints.length) {
      return [];
    }

    return _filteredPaints.sublist(
      startIndex,
      endIndex < _filteredPaints.length ? endIndex : _filteredPaints.length,
    );
  }

  /// Número total de páginas basado en la cantidad de pinturas filtradas
  int get totalPages => (_filteredPaints.length / pageSize).ceil();

  /// Lista de marcas únicas disponibles
  List<String> get availableBrands {
    final brands = _allPaints.map((paint) => paint.brand).toSet().toList();
    brands.sort();
    return ['All', ...brands];
  }

  /// Lista de categorías únicas disponibles
  List<String> get availableCategories {
    final categories =
        _allPaints.map((paint) => paint.category).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }

  /// Verificar si una pintura está en la wishlist
  bool isPaintInWishlist(String paintId) => _wishlist.contains(paintId);

  /// Cargar todas las pinturas
  Future<void> loadPaints() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      _allPaints = await _paintRepository.getAll();
      _applyFilters();
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Error al cargar las pinturas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Buscar pinturas por texto
  void searchPaints(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Establecer el filtro de marca
  void filterByBrand(String brand) {
    _selectedBrand = brand;
    _applyFilters();
  }

  /// Establecer el filtro de categoría
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  /// Establecer el filtro de color
  void filterByColor(Color? color) {
    _selectedColor = color;
    _applyFilters();
  }

  /// Restablecer todos los filtros
  void resetFilters() {
    _searchQuery = '';
    _selectedBrand = 'All';
    _selectedCategory = 'All';
    _selectedColor = null;
    _applyFilters();
  }

  /// Aplicar todos los filtros actuales a la lista de pinturas
  void _applyFilters() {
    _filteredPaints =
        _allPaints.where((paint) {
          // Filtrar por búsqueda de texto
          final nameMatches =
              paint.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              paint.brand.toLowerCase().contains(_searchQuery.toLowerCase());

          // Filtrar por marca
          final brandMatches =
              _selectedBrand == 'All' ||
              paint.brand.toLowerCase() == _selectedBrand.toLowerCase();

          // Filtrar por categoría
          final categoryMatches =
              _selectedCategory == 'All' ||
              paint.category.toLowerCase() == _selectedCategory.toLowerCase();

          // Filtrar por color (si hay seleccionado)
          bool colorMatches = true;
          if (_selectedColor != null) {
            final paintColor = _getColorFromHex(paint);

            // Comprobar similitud de color con tolerancia
            const tolerance = 50;
            final redDiff = (paintColor.red - _selectedColor!.red).abs();
            final greenDiff = (paintColor.green - _selectedColor!.green).abs();
            final blueDiff = (paintColor.blue - _selectedColor!.blue).abs();

            colorMatches =
                redDiff < tolerance &&
                greenDiff < tolerance &&
                blueDiff < tolerance;
          }

          return nameMatches && brandMatches && categoryMatches && colorMatches;
        }).toList();

    // Resetear la paginación cuando cambian los filtros
    _currentPage = 1;

    notifyListeners();
  }

  /// Cambiar a una página específica
  void goToPage(int page) {
    if (page < 1 || page > totalPages) return;
    _currentPage = page;
    notifyListeners();
  }

  /// Cambiar el tamaño de página
  void setPageSize(int size) {
    _pageSize = size;
    _currentPage = 1; // Volver a la primera página
    notifyListeners();
  }

  /// Añadir o quitar una pintura de la wishlist
  void toggleWishlist(String paintId) {
    if (_wishlist.contains(paintId)) {
      _wishlist.remove(paintId);
    } else {
      _wishlist.add(paintId);
    }
    notifyListeners();
  }

  /// Cargar datos iniciales
  void init() {
    loadPaints();

    // Aquí se podría cargar la wishlist de preferencias o API
    // _loadWishlist();
  }

  /// Guardar los datos persistentes al cerrar
  void dispose() {
    // Aquí se podrían guardar las preferencias como la wishlist
    // _saveWishlist();
    super.dispose();
  }

  Color _getColorFromHex(Paint paint) {
    return Color(int.parse(paint.hex.substring(1, 7), radix: 16) + 0xFF000000);
  }
}
