import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';

/// A service for handling barcode scanning and paint lookup functionality
class BarcodeService {
  /// Finds a paint by its barcode in the database
  ///
  /// Returns null if no matching paint is found
  Future<Paint?> findPaintByBarcode(String barcode) async {
    // In a real app, this would make an API call to look up the paint
    // For demo purposes, we'll simulate this with a delay and sample data

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Get sample paints
    final List<Paint> allPaints = SampleData.getPaints();

    // Generate fake barcodes for the sample paints using the same algorithm as in SampleData
    final Map<String, Paint> paintsByBarcode = {};
    for (final paint in allPaints) {
      final String fakeBarcode = '50119${paint.id.hashCode.abs() % 10000000}';
      paintsByBarcode[fakeBarcode] = paint;
    }

    // Look up the paint by barcode
    return paintsByBarcode[barcode];
  }

  /// Validates if a string is a proper barcode format
  ///
  /// This simple validation just checks for numeric data of appropriate length
  bool isValidBarcode(String code) {
    // Most paint barcodes are either EAN-13 (13 digits) or UPC (12 digits)
    return RegExp(r'^\d{12,13}$').hasMatch(code);
  }
}
