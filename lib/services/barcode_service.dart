import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

/// A service for handling barcode scanning and paint lookup functionality
class BarcodeService {
  static const String baseUrl = 'https://paints-api.reachu.io/api';

  /// Encuentra una pintura por su código de barras en la base de datos
  ///
  /// Devuelve null si no se encuentra una pintura coincidente
  Future<List<Paint>?> findPaintByBarcode(String barcode) async {
    if (barcode.isEmpty) {
      print('❌ Barcode is empty');
      return null;
    }

    try {
      // Normalize barcode (remove spaces, dashes, etc.)
      final normalized = _normalizeBarcode(barcode);
      print('🔍 Searching for paint with barcode: $normalized');

      // Get Firebase token
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return null;
      }

      final token = await user.getIdToken();
      print('🔑 Got Firebase token');

      // Make API call to find paint by barcode
      final url = Uri.parse('$baseUrl/paint/barcode/$normalized');
      print('🌐 API URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['executed'] == true && data['data'] != null && data['data'].isNotEmpty) {
          final List<Paint> paints = [];
          
          for (final paintData in data['data']) {
            print('✅ Found paint: ${paintData['name']} (${paintData['brand']})');
            
            // Asegurarse de que las paletas vengan exactamente como la API las envía
            final List<String> palettes = (paintData['palettes'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ?? [];
            
            print('📦 Palettes from API: $palettes');
            
            // Crear el objeto Paint con las paletas exactamente como vienen de la API
            final paint = Paint(
              id: paintData['id'],
              brand: paintData['brand'],
              brandId: paintData['brandId'],
              name: paintData['name'],
              code: paintData['code'],
              set: paintData['set'],
              r: paintData['r'],
              g: paintData['g'],
              b: paintData['b'],
              hex: paintData['hex'],
              category: paintData['category'] ?? '',
              isMetallic: paintData['isMetallic'] ?? false,
              isTransparent: paintData['isTransparent'] ?? false,
              palettes: palettes, // Usar las paletas exactamente como vienen de la API
            );
            
            print('🎨 Created Paint object with palettes: ${paint.palettes}');
            paints.add(paint);
          }
          
          return paints;
        } else {
          print('⚠️ No paint found in API response');
          return null;
        }
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error finding paint by barcode: $e');
      return null;
    }
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

      return false;
    } catch (e) {
      print('Error validating barcode: $e');
      return false;
    }
  }

  /// Normalizes a barcode string by removing unwanted characters
  String _normalizeBarcode(String code) {
    // Remove spaces, dashes, and other common separators
    return code.trim().replaceAll(RegExp(r'[\s\-_.,:/\\]'), '').toUpperCase();
  }
}
