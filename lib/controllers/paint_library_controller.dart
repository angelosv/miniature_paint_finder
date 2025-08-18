import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/services/paint_api_service.dart';
import 'package:miniature_paint_finder/services/library_cache_service.dart';

/// Controlador para manejar la lógica de la pantalla de biblioteca de pinturas
/// Ahora optimizado con cache inteligente para mejor performance
class PaintLibraryController extends ChangeNotifier {
  /// Servicios para acceder a datos de pinturas
  final PaintApiService _apiService;
  final LibraryCacheService _cacheService;

  /// Lista completa de pinturas cargadas
  List<Paint> _allPaints = [];

  /// Lista de pinturas filtrada
  List<Paint> _filteredPaints = [];

  /// Lista de marcas únicas disponibles
  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _categories = [];

  /// Flag para controlar la vista de biblioteca (True = Vista de marcas, False = Vista de pinturas)
  bool _showingBrandsView = true;

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
  int _pageSize = 100;

  /// Lista de marcas únicas disponibles
  List<String> _availableBrands = ['All'];

  /// Lista de categorías únicas disponibles
  List<String> _availableCategories = ['All'];

  /// Lista de tamaños de página disponibles
  List<int> pageSizeOptions = [25, 50, 100];

  /// Constructor que recibe los servicios
  PaintLibraryController(this._apiService, this._cacheService);

  /// Getters para acceder a los datos desde la UI
  List<Paint> get allPaints => _allPaints;
  List<Paint> get filteredPaints => _filteredPaints;
  Set<String> get wishlist => _wishlist;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedBrand => _selectedBrand;
  bool get showingBrandsView => _showingBrandsView;
  List<Map<String, dynamic>> get brands => _brands;

  /// Getter para saber si el cache está precargando datos
  bool get isPreloading => _cacheService.isPreloading;

  set selectedBrand(String value) {
    _selectedBrand = value;
    notifyListeners();
  }

  String get selectedCategory => _selectedCategory;
  set selectedCategory(String value) {
    _selectedCategory = value;
    notifyListeners();
  }

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
    return _availableCategories;
  }

  /// Verificar si una pintura está en la wishlist
  bool isPaintInWishlist(String paintId) => _wishlist.contains(paintId);

  /// Alterna entre la vista de marcas y la vista de pinturas
  void toggleView() {
    _showingBrandsView = !_showingBrandsView;
    if (_showingBrandsView) {
      _selectedBrand = 'All';
    }
    notifyListeners();
  }

  /// Establece la vista a mostrar
  void setView(bool showBrands) {
    if (_showingBrandsView != showBrands) {
      _showingBrandsView = showBrands;
      notifyListeners();
    }
  }

  /// Navega a la vista de pinturas de una marca específica
  void navigateToBrandPaints(String brandName) {
    _showingBrandsView = false;
    filterByBrand(brandName, true);
  }

  /// Vuelve a la vista de marcas
  void backToBrandsView() {
    _showingBrandsView = true;
    _selectedBrand = 'All';
    notifyListeners();
  }

  /// Obtiene marcas con conteo de pinturas
  List<Map<String, dynamic>> getBrandsWithCounts() {
    // Si ya tenemos las marcas cargadas, las devolvemos directamente
    return _brands;
  }

  /// Cargar todas las pinturas usando el cache inteligente
  Future<void> loadPaints({bool forceRefresh = false}) async {
    debugPrint(
      '🎨 Loading paints - Page: $_currentPage, Size: $_pageSize, Brand: $_selectedBrand, Search: $_searchQuery, Category: $_selectedCategory',
    );
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      String brandId = '';
      if (_selectedBrand != 'All') {
        final matchingBrand = _brands.firstWhere(
          (brand) => brand['name'] == _selectedBrand,
          orElse: () => <String, dynamic>{},
        );
        brandId = matchingBrand['id'] as String;
      }
      debugPrint('🏷️ brandId: $brandId');

      // Usar el cache service para obtener las pinturas
      final result = await _cacheService.getPaints(
        page: _currentPage,
        limit: _pageSize,
        brandId: brandId.isEmpty ? null : brandId,
        name: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        forceRefresh: forceRefresh,
      );

      debugPrint(
        '✅ API Response - Total: ${result['totalPaints']}, Pages: ${result['totalPages']}, Current: ${result['currentPage']}',
      );

      _allPaints = result['paints'] as List<Paint>;
      _filteredPaints = _allPaints;
      _currentPage = result['currentPage'] as int;
      _totalPages = result['totalPages'] as int;
      _totalPaints = result['totalPaints'] as int;
    } catch (e) {
      debugPrint('❌ Error loading paints: $e');
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

  /// Establecer el filtro de marca recibiendo el nombre de la marca y obteniendo su id.
  void filterByBrand(String brandName, bool reset) {
    debugPrint('🏷️ filterByBrand: $brandName');
    if (brandName == 'All') {
      _selectedBrand = 'All';
    } else {
      _selectedBrand = brandName;
    }
    debugPrint('🏷️ _selectedBrand: $_selectedBrand');
    if (reset) {
      _currentPage = 1;
      loadPaints();
    }
    _currentPage = 1;
    notifyListeners();
  }

  /// Establecer el filtro de categoría
  void filterByCategory(String category, bool reset) {
    _selectedCategory = category;
    if (reset) {
      _currentPage = 1;
      loadPaints();
    }
    notifyListeners();
  }

  /// Establecer el filtro de color
  void filterByColor(Color? color) {
    _selectedColor = color;
    applyFilters();
  }

  /// Restablecer todos los filtros
  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _selectedColor = null;
    applyFilters();
  }

  /// Aplicar todos los filtros actuales a la lista de pinturas
  void applyFilters() {
    _currentPage = 1;
    loadPaints();
  }

  /// Cambiar a una página específica
  void goToPage(int page) {
    debugPrint('📄 Going to page: $page');
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    loadPaints();
  }

  /// Cambiar el tamaño de página
  void setPageSize(int size) {
    debugPrint('📏 Changing page size to: $size');
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

  /// Cargar marcas usando el cache inteligente
  Future<void> loadBrands({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Usar el cache service para obtener las marcas
      final brands = await _cacheService.getBrands(forceRefresh: forceRefresh);

      // Actualizar el estado
      _brands = brands;
      _availableBrands = ['All', ...brands.map((b) => b['name'] as String)];
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar las marcas: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar categorías usando el cache inteligente
  Future<void> loadCategories({bool forceRefresh = false}) async {
    try {
      // Usar el cache service para obtener las categorías
      final categories = await _cacheService.getCategories(
        forceRefresh: forceRefresh,
      );

      _categories = categories;
      _availableCategories = [
        'All',
        ...categories.map((c) => c['name'] as String),
      ];
      notifyListeners();
    } catch (e) {
      _availableCategories = ['All'];
      _errorMessage = 'Error al cargar las categorias: $e';
      notifyListeners();
    }
  }

  /// Refresca los datos forzando una nueva carga desde el API
  Future<void> refreshData() async {
    debugPrint('🔄 Forcing data refresh...');
    await Future.wait([
      loadBrands(forceRefresh: true),
      loadCategories(forceRefresh: true),
      loadPaints(forceRefresh: true),
    ]);
  }

  /// Limpia el cache y recarga los datos
  Future<void> clearCacheAndReload() async {
    debugPrint('🗑️ Clearing cache and reloading...');
    await _cacheService.clearCache();
    await refreshData();
  }

  /// Precarga datos esenciales para mejorar la experiencia del usuario
  Future<void> preloadEssentialData() async {
    await _cacheService.preloadEssentialData();
  }

  Color _getColorFromHex(Paint paint) {
    return Color(int.parse(paint.hex.substring(1, 7), radix: 16) + 0xFF000000);
  }

  /// Ir a la página anterior
  void goToPreviousPage() {
    debugPrint('◀️ Going to previous page. Current page: $_currentPage');
    if (_currentPage > 1) {
      _currentPage--;
      loadPaints();
    }
  }

  /// Ir a la página siguiente
  void goToNextPage() {
    debugPrint(
      '▶️ Going to next page. Current page: $_currentPage, Total pages: $_totalPages',
    );
    if (_currentPage < _totalPages) {
      _currentPage++;
      loadPaints();
    }
  }

  /// Guardar los datos persistentes al cerrar
  @override
  void dispose() {
    // Aquí se podrían guardar las preferencias como la wishlist
    // _saveWishlist();
    super.dispose();
  }
}
