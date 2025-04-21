import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/services/paint_api_service.dart';

/// Controller for advanced paint search functionality
class PaintSearchController extends ChangeNotifier {
  final PaintApiService _apiService;

  // Search parameters
  String _searchQuery = '';
  String _selectedBrand = 'All';
  List<String> _selectedCategories = [];
  Color? _selectedColor;
  bool _onlyInStock = false;
  bool _includeMetallic = true;
  bool _includeTransparent = true;

  // Results
  List<Paint> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  // Filter options
  List<String> _availableBrands = ['All'];
  List<String> _availableCategories = [];

  // Popular searches history
  List<String> _recentSearches = [];

  // Constructor
  PaintSearchController(this._apiService) {
    _loadInitialData();
  }

  // Getters
  String get searchQuery => _searchQuery;
  String get selectedBrand => _selectedBrand;
  List<String> get selectedCategories => _selectedCategories;
  Color? get selectedColor => _selectedColor;
  bool get onlyInStock => _onlyInStock;
  bool get includeMetallic => _includeMetallic;
  bool get includeTransparent => _includeTransparent;

  List<Paint> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<String> get availableBrands => _availableBrands;
  List<String> get availableCategories => _availableCategories;
  List<String> get recentSearches => _recentSearches;

  // Initial data loading
  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load brands from API
      final brands = await _apiService.getBrands();
      _availableBrands = ['All', ...brands.map((b) => b['name'] as String)];

      // Load recent searches from local storage (placeholder)
      _recentSearches = ['Red paint', 'Contrast paint', 'Metallic gold'];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Set brand filter
  void setBrand(String brand) {
    _selectedBrand = brand;
    notifyListeners();
  }

  // Toggle category filter
  void toggleCategory(String category, bool isSelected) {
    if (isSelected) {
      _selectedCategories.add(category);
    } else {
      _selectedCategories.remove(category);
    }
    notifyListeners();
  }

  // Set color filter
  void setColor(Color? color) {
    _selectedColor = color;
    notifyListeners();
  }

  // Toggle in-stock filter
  void toggleInStock(bool value) {
    _onlyInStock = value;
    notifyListeners();
  }

  // Toggle metallic filter
  void toggleMetallic(bool value) {
    _includeMetallic = value;
    notifyListeners();
  }

  // Toggle transparent filter
  void toggleTransparent(bool value) {
    _includeTransparent = value;
    notifyListeners();
  }

  // Reset all filters
  void resetFilters() {
    _selectedBrand = 'All';
    _selectedCategories = [];
    _selectedColor = null;
    _onlyInStock = false;
    _includeMetallic = true;
    _includeTransparent = true;
    notifyListeners();
  }

  // Add to recent searches
  void addToRecentSearches(String query) {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
      // TODO: Save to local storage
      notifyListeners();
    }
  }

  // Perform search with current parameters
  Future<void> search() async {
    if (_searchQuery.isEmpty &&
        _selectedBrand == 'All' &&
        _selectedCategories.isEmpty &&
        _selectedColor == null) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Add current query to recent searches
      if (_searchQuery.isNotEmpty) {
        addToRecentSearches(_searchQuery);
      }

      // Convert brand selection to brandId for API
      String? brandId;
      if (_selectedBrand != 'All') {
        final brands = await _apiService.getBrands();
        final selectedBrandInfo = brands.firstWhere(
          (b) => b['name'] == _selectedBrand,
          orElse: () => {'id': null},
        );
        brandId = selectedBrandInfo['id'] as String?;
      }

      // Call API with filters
      final result = await _apiService.getPaints(
        name: _searchQuery.isNotEmpty ? _searchQuery : null,
        brandId: brandId,
        // Additional filters would be passed here in a real implementation
      );

      _searchResults = result['paints'] as List<Paint>;

      // Apply client-side filtering for categories and other filters
      if (_selectedCategories.isNotEmpty) {
        _searchResults =
            _searchResults
                .where((paint) => _selectedCategories.contains(paint.category))
                .toList();
      }

      if (!_includeMetallic) {
        _searchResults =
            _searchResults.where((paint) => !paint.isMetallic).toList();
      }

      if (!_includeTransparent) {
        _searchResults =
            _searchResults.where((paint) => !paint.isTransparent).toList();
      }
    } catch (e) {
      _error = 'Error searching paints: $e';
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search by color
  Future<void> searchByColor(Color color) async {
    _isLoading = true;
    _error = null;
    _selectedColor = color;
    notifyListeners();

    try {
      // Convert color to hex
      final String colorHex =
          '#${color.value.toRadixString(16).substring(2).padLeft(6, '0')}';

      // In a real implementation, this would call a specialized endpoint
      // For now, we'll just filter by the hex code
      final allPaints = await _apiService.getPaints(limit: 200);

      // Simple color matching algorithm - in a real app this would be more sophisticated
      _searchResults =
          (allPaints['paints'] as List<Paint>).where((paint) {
            final paintColor = Color(
              int.parse(paint.hex.substring(1), radix: 16) + 0xFF000000,
            );

            // Calculate color distance - very basic implementation
            final rDist = (paintColor.red - color.red).abs();
            final gDist = (paintColor.green - color.green).abs();
            final bDist = (paintColor.blue - color.blue).abs();

            // Color is "close enough" if the combined distance is below threshold
            return (rDist + gDist + bDist) < 150; // Arbitrary threshold
          }).toList();
    } catch (e) {
      _error = 'Error searching by color: $e';
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
