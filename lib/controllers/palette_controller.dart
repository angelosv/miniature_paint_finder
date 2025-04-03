import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/repositories/palette_repository.dart';

/// Controller for palette-related operations
class PaletteController extends ChangeNotifier {
  final PaletteRepository _repository;

  List<Palette> _palettes = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalPalettes = 0;
  int _limit = 10;

  /// Constructor
  PaletteController(this._repository) {
    // Cargar paletas inmediatamente
    loadPalettes();
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

  /// Load all palettes for the current user
  Future<void> loadPalettes({int? page}) async {
    print('🎨 PaletteController.loadPalettes() called with page: $page');
    try {
      _isLoading = true;
      notifyListeners();

      final currentPage = page ?? _currentPage;
      print('🎨 Loading palettes for page: $currentPage');

      final palettes = await _repository.getUserPalettes(
        page: currentPage,
        limit: _limit,
      );

      print('🎨 Got ${palettes.length} palettes from repository');

      if (currentPage == 1) {
        _palettes = palettes;
      } else {
        _palettes = [..._palettes, ...palettes];
      }

      _currentPage = currentPage;
      _totalPages = (palettes.length / _limit).ceil();
      _totalPalettes = palettes.length;

      print('🎨 Updated state:');
      print('  - Current page: $_currentPage');
      print('  - Total pages: $_totalPages');
      print('  - Total palettes: $_totalPalettes');
      print('  - Palettes loaded: ${_palettes.length}');

      for (var i = 0; i < _palettes.length; i++) {
        final palette = _palettes[i];
        print('  🎨 Palette ${i + 1}:');
        print('    - Name: ${palette.name}');
        print('    - Image Path: ${palette.imagePath}');
        print('    - Colors: ${palette.colors.length}');
        print(
          '    - Paint Selections: ${palette.paintSelections?.length ?? 0}',
        );
      }
    } catch (e) {
      print('❌ Error loading palettes: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load next page of palettes
  Future<void> loadNextPage() async {
    if (_currentPage < _totalPages) {
      await loadPalettes(page: _currentPage + 1);
    }
  }

  /// Load previous page of palettes
  Future<void> loadPreviousPage() async {
    if (_currentPage > 1) {
      await loadPalettes(page: _currentPage - 1);
    }
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
      final palette = Palette(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        imagePath: imagePath,
        colors: colors,
        createdAt: DateTime.now(),
      );

      final createdPalette = await _repository.create(palette);
      _palettes.add(createdPalette);
      notifyListeners();
      return createdPalette;
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
      final success = await _repository.delete(paletteId);
      if (success) {
        _palettes.removeWhere((palette) => palette.id == paletteId);
        notifyListeners();
      }
      return success;
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
      final success = await _repository.addPaintToPalette(
        paletteId,
        paint.id,
        hex,
      );

      if (success) {
        await loadPalettes(); // Reload to get updated data
      }

      return success;
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
      final success = await _repository.removePaintFromPalette(
        paletteId,
        paintId,
      );

      if (success) {
        await loadPalettes(); // Reload to get updated data
      }

      return success;
    } catch (e) {
      _error = 'Failed to remove paint from palette: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
