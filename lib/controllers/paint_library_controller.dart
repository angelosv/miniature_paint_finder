import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/services/paint_api_service.dart';

/// Controlador para manejar la lógica de la pantalla de biblioteca de pinturas
class PaintLibraryController extends ChangeNotifier {
  /// Repositorio para acceder a datos de pinturas
  final PaintApiService _apiService;

  /// Lista completa de pinturas cargadas
  List<Paint> _allPaints = [];

  /// Lista de pinturas filtrada
  List<Paint> _filteredPaints = [];

  /// Lista de marcas únicas disponibles
  List<Map<String, dynamic>> _brands = [];

  /// Conjunto de IDs de pinturas en la lista de deseos
  Set<String> _wishlist = {};

  /// Estados de la carga
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  /// Filtros actuales
  String _searchQuery = '';
  String _selectedBrand = 'All';
  String _selectedCategory = 'All';
  Color? _selectedColor;

  /// Configuración de paginación
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalPaints = 0;
  int _pageSize = 25;

  /// Lista de marcas únicas disponibles
  List<String> _availableBrands = ['All'];

  /// Lista de categorías únicas disponibles
  List<String> _availableCategories = ['All'];

  /// Lista de tamaños de página disponibles
  List<int> pageSizeOptions = [25, 50, 100];

  /// Constructor que recibe el repositorio
  PaintLibraryController(this._apiService);

  /// Getters para acceder a los datos desde la UI
  List<Paint> get allPaints => _allPaints;
  List<Paint> get filteredPaints => _filteredPaints;
  Set<String> get wishlist => _wishlist;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedBrand => _selectedBrand;
  String get selectedCategory => _selectedCategory;
  Color? get selectedColor => _selectedColor;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => _totalPages;
  int get totalPaints => _totalPaints;

  /// Lista de pinturas paginadas para la UI
  List<Paint> get paginatedPaints => _filteredPaints;

  /// Lista de marcas únicas disponibles
  List<String> get availableBrands {
    return _availableBrands;
  }

  /// Lista de categorías únicas disponibles
  List<String> get availableCategories {
    final categories = _allPaints.map((paint) => paint.category).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }

  /// Verificar si una pintura está en la wishlist
  bool isPaintInWishlist(String paintId) => _wishlist.contains(paintId);

  /// Cargar todas las pinturas
  Future<void> loadPaints() async {
    print('Loading paints - Page: $_currentPage, Size: $_pageSize, Brand: $_selectedBrand, Search: $_searchQuery');
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.getPaints(
        page: _currentPage,
        limit: _pageSize,
        brandId: _selectedBrand == 'All' ? null : _selectedBrand,
        name: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      print('API Response - Total: ${result['totalPaints']}, Pages: ${result['totalPages']}, Current: ${result['currentPage']}');

      _allPaints = result['paints'] as List<Paint>;
      _filteredPaints = _allPaints;
      _currentPage = result['currentPage'] as int;
      _totalPages = result['totalPages'] as int;
      _totalPaints = result['totalPaints'] as int;

      await _loadBrands();
    } catch (e) {
      print('Error loading paints: $e');
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
    _currentPage = 1;
    loadPaints();
  }

  /// Establecer el filtro de marca
  void filterByBrand(String brand) {
    _selectedBrand = brand;
    _currentPage = 1;
    loadPaints();
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
    _filteredPaints = _allPaints.where((paint) {
      if (_selectedCategory != 'All' && paint.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();
    notifyListeners();
  }

  /// Cambiar a una página específica
  void goToPage(int page) {
    print('Going to page: $page');
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    loadPaints();
  }

  /// Cambiar el tamaño de página
  void setPageSize(int size) {
    print('Changing page size to: $size');
    _pageSize = size;
    _currentPage = 1; // Volver a la primera página
    loadPaints();
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

  Future<void> _loadBrands() async {
    try {
      final brands = await _apiService.getBrands();
      _brands = brands;
      _availableBrands = ['All', ...brands.map((b) => b['name'] as String)];
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar las marcas: $e';
      notifyListeners();
    }
  }

  Color _getColorFromHex(Paint paint) {
    return Color(int.parse(paint.hex.substring(1, 7), radix: 16) + 0xFF000000);
  }

  /// Ir a la página anterior
  void goToPreviousPage() {
    print('Going to previous page. Current page: $_currentPage');
    if (_currentPage > 1) {
      _currentPage--;
      loadPaints();
    }
  }

  /// Ir a la página siguiente
  void goToNextPage() {
    print('Going to next page. Current page: $_currentPage, Total pages: $_totalPages');
    if (_currentPage < _totalPages) {
      _currentPage++;
      loadPaints();
    }
  }
}
