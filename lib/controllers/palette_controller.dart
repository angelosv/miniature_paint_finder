import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/repositories/palette_repository.dart';
import 'package:miniature_paint_finder/services/palette_cache_service.dart';

/// Controller for palette-related operations
class PaletteController extends ChangeNotifier {
  final PaletteRepository _repository;
  final PaletteCacheService? _cacheService;

  List<Palette> _palettes = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalPalettes = 0;
  int _limit = 10;
  bool _hasInitialLoaded = false;

  /// Constructor
  PaletteController(this._repository, [this._cacheService]) {
    // Don't auto-load in constructor to prevent loops
    // Load will be triggered by UI when needed
    debugPrint(
      '🎨 PaletteController created, cache service initialized: ${_cacheService?.isInitialized}',
    );
  }

  /// All palettes owned by the user
  List<Palette> get palettes => _palettes;

  /// Whether data is currently loading
  bool get isLoading => _isLoading;

  /// Any error that occurred during loading
  String? get error => _error;

  /// Current page number
  int get currentPage => _currentPage;

  /// Total number of pages
  int get totalPages => _totalPages;

  /// Total number of palettes
  int get totalPalettes => _totalPalettes;

  /// Number of items per page
  int get limit => _limit;

  /// Whether initial load has been completed
  bool get hasInitialLoaded => _hasInitialLoaded;

  /// Debug method to check cache service state
  void debugCacheServiceState() {
    debugPrint('🔍 ========== PALETTE CONTROLLER DEBUG ==========');
    debugPrint('🔍 Controller palettes: ${_palettes.length}');
    debugPrint('🔍 Has initial loaded: $_hasInitialLoaded');
    debugPrint('🔍 Is loading: $_isLoading');
    debugPrint('🔍 Error: $_error');
    debugPrint('🔍 Cache service available: ${_cacheService != null}');
    debugPrint('🔍 Cache service initialized: ${_cacheService?.isInitialized}');

    if (_cacheService != null) {
      _cacheService!.debugCacheState();
    }
    debugPrint('🔍 ===============================================');
  }

  /// Test cache functionality (useful for debugging issues)
  Future<Map<String, dynamic>> testCacheFunctionality() async {
    debugPrint('🧪 Testing palette cache functionality...');

    if (_cacheService?.isInitialized == true) {
      return await _cacheService!.testCacheFunctionality();
    } else {
      return {
        'overall_status': 'failed',
        'error': 'Cache service not available or not initialized',
        'cache_service_available': _cacheService != null,
        'cache_service_initialized': _cacheService?.isInitialized ?? false,
      };
    }
  }

  /// Debug pending operations
  Future<void> debugPendingOperations() async {
    debugPrint('🔧 Debugging palette pending operations...');

    if (_cacheService?.isInitialized == true) {
      await _cacheService!.debugProcessPendingOperations();
    } else {
      debugPrint('❌ Cache service not available or not initialized');
    }
  }

  /// Force sync with server
  Future<void> forceSync() async {
    debugPrint('🔄 Forcing palette sync...');

    if (_cacheService?.isInitialized == true) {
      await _cacheService!.forceSync();
    } else {
      debugPrint('❌ Cache service not available or not initialized');
    }
  }

  /// Force refresh palette list - useful after external palette creation
  Future<void> refreshPalettes() async {
    debugPrint('🎨 Force refreshing palettes...');

    // Invalidate cache to force fresh data
    if (_cacheService?.isInitialized == true) {
      _cacheService!.invalidateCache();
    }

    _hasInitialLoaded = false; // Reset to allow fresh load
    await loadPalettes(forceRefresh: true);
  }

  /// Invalidate cache when external changes occur
  void invalidateCache() {
    if (_cacheService?.isInitialized == true) {
      _cacheService!.invalidateCache();
    }
  }

  /// Load all palettes for the current user
  Future<void> loadPalettes({int? page, bool forceRefresh = false}) async {
    // Prevent duplicate calls if already loading
    if (_isLoading && !forceRefresh) {
      debugPrint('🎨 Already loading palettes, skipping duplicate call');
      return;
    }

    // If we have data and this is not a force refresh, skip
    if (_hasInitialLoaded && !forceRefresh && _palettes.isNotEmpty) {
      debugPrint(
        '🎨 Palettes already loaded (${_palettes.length}), skipping reload',
      );
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('🎨 Loading palettes...');

      // Use cache service if available and initialized (same pattern as wishlist/inventory)
      if (_cacheService?.isInitialized == true) {
        debugPrint('🎨 Loading palettes via cache service');
        _palettes = await _cacheService!.getPalettes(
          forceRefresh: forceRefresh,
        );

        // Update pagination from cache service
        _currentPage = _cacheService!.currentPage;
        _totalPages = _cacheService!.totalPages;
        _totalPalettes = _cacheService!.totalPalettes;
        _limit = _cacheService!.limit;

        debugPrint('🎨 Cache service returned ${_palettes.length} palettes');
      } else {
        // Fallback to repository only if cache service is not available
        debugPrint('🎨 Loading palettes via repository (fallback)');
        final requestPage = page ?? _currentPage;
        final result = await _repository.getUserPalettes(
          page: requestPage,
          limit: _limit,
        );
        // Use repository data when cache service is not available
        _palettes = result['palettes'];

        // Update pagination using repository data
        _currentPage = int.parse(result['currentPage'].toString());
        _totalPages = int.parse(result['totalPages'].toString());
        _totalPalettes = int.parse(result['totalPalettes'].toString());
        _limit = int.parse(result['limit'].toString());

        debugPrint('🎨 Repository returned ${_palettes.length} palettes');
      }

      _hasInitialLoaded = true;
    } catch (e) {
      debugPrint('❌ Error loading palettes: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search palettes by name (client-side filtering like wishlist/inventory)
  List<Palette> searchPalettes(String query) {
    if (query.isEmpty) return _palettes;

    return _palettes.where((palette) {
      return palette.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Create a new palette
  Future<Palette?> createPalette({
    required String name,
    required String imagePath,
    required List<Color> colors,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use cache service if available and initialized
      if (_cacheService?.isInitialized == true) {
        debugPrint('🎨 Creating palette via cache service');
        final success = await _cacheService!.createPalette(
          name: name,
          imagePath: imagePath,
          colors: colors,
        );

        if (success) {
          // Refresh local data from cache
          _palettes = _cacheService!.cachedPalettes ?? _palettes;
          _totalPalettes = _cacheService!.totalPalettes;

          // Force a refresh to ensure UI is updated
          debugPrint('🎨 Palette created successfully, triggering refresh');
          notifyListeners();

          return _palettes.firstWhere((p) => p.name == name);
        }
        return null;
      } else {
        // Fallback to repository
        debugPrint('🎨 Creating palette via repository (fallback)');
        final palette = Palette(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          imagePath: imagePath,
          colors: colors,
          createdAt: DateTime.now(),
          totalPaints: colors.length,
          createdAtText: 'Just now',
        );

        final createdPalette = await _repository.create(palette);
        _palettes.add(createdPalette);
        notifyListeners();
        return createdPalette;
      }
    } catch (e) {
      _error = 'Failed to create palette: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a palette
  Future<bool> deletePalette(String paletteId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use cache service if available and initialized
      if (_cacheService?.isInitialized == true) {
        debugPrint('🎨 Deleting palette via cache service');
        final success = await _cacheService!.deletePalette(paletteId);

        if (success) {
          // Refresh local data from cache
          _palettes = _cacheService!.cachedPalettes ?? _palettes;
          _totalPalettes = _cacheService!.totalPalettes;
        }

        return success;
      } else {
        // Fallback to repository
        debugPrint('🎨 Deleting palette via repository (fallback)');
        final success = await _repository.delete(paletteId);
        if (success) {
          _palettes.removeWhere((palette) => palette.id == paletteId);
          notifyListeners();
        }
        return success;
      }
    } catch (e) {
      _error = 'Failed to delete palette: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a paint to a palette
  Future<bool> addPaintToPalette(
    String paletteId,
    Paint paint,
    String hex,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use cache service if available and initialized
      if (_cacheService?.isInitialized == true) {
        debugPrint('🎨 Adding paint to palette via cache service');
        final success = await _cacheService!.addPaintToPalette(
          paletteId,
          paint,
          hex,
        );

        if (success) {
          // Refresh local data from cache
          _palettes = _cacheService!.cachedPalettes ?? _palettes;
        }

        return success;
      } else {
        // Fallback to repository
        debugPrint('🎨 Adding paint to palette via repository (fallback)');
        final success = await _repository.addPaintToPalette(
          paletteId,
          paint.id,
          hex,
        );

        if (success) {
          await loadPalettes(); // Reload to get updated data
        }

        return success;
      }
    } catch (e) {
      _error = 'Failed to add paint to palette: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Remove a paint from a palette
  Future<bool> removePaintFromPalette(String paletteId, String paintId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use cache service if available and initialized
      if (_cacheService?.isInitialized == true) {
        debugPrint('🎨 Removing paint from palette via cache service');
        final success = await _cacheService!.removePaintFromPalette(
          paletteId,
          paintId,
        );

        if (success) {
          // Refresh local data from cache
          _palettes = _cacheService!.cachedPalettes ?? _palettes;
        }

        return success;
      } else {
        // Fallback to repository
        debugPrint('🎨 Removing paint from palette via repository (fallback)');
        final success = await _repository.removePaintFromPalette(
          paletteId,
          paintId,
        );

        if (success) {
          await loadPalettes(); // Reload to get updated data
        }

        return success;
      }
    } catch (e) {
      _error = 'Failed to remove paint from palette: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
