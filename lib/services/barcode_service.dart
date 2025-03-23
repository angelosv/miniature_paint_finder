import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';

/// A service for handling barcode scanning and paint lookup functionality
class BarcodeService {
  // Cache de pinturas para evitar cálculos repetitivos
  Map<String, Paint>? _paintsBarcodeCache;

  /// Encuentra una pintura por su código de barras en la base de datos
  ///
  /// Devuelve null si no se encuentra una pintura coincidente
  Future<Paint?> findPaintByBarcode(String barcode) async {
    if (barcode.isEmpty) {
      return null;
    }

    try {
      // Normalize barcode (remove spaces, dashes, etc.)
      final normalized = _normalizeBarcode(barcode);

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Inicializar el cache si no existe
      _paintsBarcodeCache ??= _generateBarcodePaintMap();

      // Buscar en el cache usando la versión normalizada primero, luego la original
      return _paintsBarcodeCache![normalized] ??
          _paintsBarcodeCache![barcode] ??
          _searchSimilarBarcode(normalized);
    } catch (e) {
      print('Error finding paint by barcode: $e');
      return null;
    }
  }

  /// Genera un mapa de códigos de barras a pinturas
  Map<String, Paint> _generateBarcodePaintMap() {
    final Map<String, Paint> paintsByBarcode = {};
    final List<Paint> allPaints = SampleData.getPaints();

    // Create multiple barcode formats for each paint to increase chances of matches
    for (final paint in allPaints) {
      // Standard EAN-13 format
      final String ean13 = '50119${paint.id.hashCode.abs() % 10000000}';
      paintsByBarcode[ean13] = paint;

      // UPC format (12 digits)
      if (ean13.startsWith('0')) {
        paintsByBarcode[ean13.substring(1)] = paint;
      }

      // EAN-8 format (8 digits)
      final String ean8 = '50${paint.id.hashCode.abs() % 100000}';
      paintsByBarcode[ean8] = paint;

      // QR code version with a prefix
      paintsByBarcode['PAINT-${paint.id}'] = paint;

      // Brand specific format
      final String brandCode =
          '${paint.brand.substring(0, min(3, paint.brand.length)).toUpperCase()}${paint.id.hashCode.abs() % 1000000}';
      paintsByBarcode[brandCode] = paint;

      // Código basado en nombre y marca
      final String nameCode =
          '${paint.name.substring(0, min(3, paint.name.length)).toUpperCase()}${paint.brand.hashCode.abs() % 10000}';
      paintsByBarcode[nameCode] = paint;

      // Para demostración: asociar algunos códigos cortos para facilitar el escaneo de cualquier código
      final String demoCode = '${paint.id.hashCode.abs() % 1000000}';
      paintsByBarcode[demoCode] = paint;
    }

    return paintsByBarcode;
  }

  /// Busca un código de barras similar
  Paint? _searchSimilarBarcode(String code) {
    if (_paintsBarcodeCache == null || code.length < 4) {
      return null;
    }

    // Intentar encontrar un código que contenga este como subcadena
    for (final entry in _paintsBarcodeCache!.entries) {
      if (entry.key.contains(code) || code.contains(entry.key)) {
        return entry.value;
      }
    }

    // Si el código es numérico, tratar de encontrar un código similar
    if (RegExp(r'^\d+$').hasMatch(code) && code.length >= 6) {
      final String codeStart = code.substring(0, 4);
      for (final entry in _paintsBarcodeCache!.entries) {
        if (entry.key.startsWith(codeStart) &&
            entry.key.length >= 6 &&
            RegExp(r'^\d+$').hasMatch(entry.key)) {
          return entry.value;
        }
      }
    }

    return null;
  }

  /// Validates if a string is a proper barcode format
  ///
  /// This validation checks for common paint barcode formats
  bool isValidBarcode(String code) {
    if (code.isEmpty) {
      return false;
    }

    try {
      // Normalize the code first
      final normalized = _normalizeBarcode(code);

      // Regular barcode formats (EAN-13, UPC, etc.)
      if (RegExp(r'^\d{6,14}$').hasMatch(normalized)) {
        return true;
      }

      // QR code format with PAINT prefix
      if (normalized.startsWith('PAINT')) {
        return true;
      }

      // Alphanumeric format that might be used by manufacturers
      if (RegExp(r'^[A-Z]{1,4}\d{3,8}$').hasMatch(normalized)) {
        return true;
      }

      // Para demo, aceptar cualquier código con al menos 3 caracteres
      if (normalized.length >= 3) {
        return true;
      }

      return false;
    } catch (e) {
      print('Error validating barcode: $e');
      // En caso de error, aceptamos el código para procesarlo después
      return code.length >= 3;
    }
  }

  /// Normalizes a barcode string by removing unwanted characters
  String _normalizeBarcode(String code) {
    // Remove spaces, dashes, and other common separators
    return code.trim().replaceAll(RegExp(r'[\s\-_.,:/\\]'), '').toUpperCase();
  }

  /// Utility to get minimum of two integers
  int min(int a, int b) => a < b ? a : b;
}
