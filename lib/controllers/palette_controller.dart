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

  /// Load all palettes for the current user
  Future<void> loadPalettes() async {
    print('🔄 Starting to load palettes');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📦 Calling repository.getUserPalettes()');
      _palettes = await _repository.getUserPalettes();
      print('✅ Loaded ${_palettes.length} palettes successfully');
      for (var i = 0; i < _palettes.length; i++) {
        print(
          '  🎨 Palette ${i + 1}: ${_palettes[i].name} (${_palettes[i].colors.length} colors)',
        );
        print('  🖼️ Image path: ${_palettes[i].imagePath}');
      }
    } catch (e) {
      print('❌ Error loading palettes: $e');
      _error = 'Failed to load palettes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
      print('🏁 Finished loading palettes (success=${_error == null})');
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
    String colorHex,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.addPaintToPalette(
        paletteId,
        paint.id,
        colorHex,
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
