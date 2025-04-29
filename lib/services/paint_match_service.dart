// lib/services/paint_match_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:miniature_paint_finder/utils/env.dart';

class PaintMatchService {
  static final String baseUrl = '${Env.apiBaseUrl}/api';

  Future<Map<String, dynamic>> fetchMatchingPaints({
    required String hexColor,
    required List<String> brandIds,
    int limit = 10,
    int page = 1,
  }) async {
    // Asegurar que el hex no tenga # y sea válido
    final hex = hexColor.replaceAll('#', '').padLeft(6, '0');
    final brandsParam = brandIds.join(',');

    final url = Uri.parse(
      '$baseUrl/paint/closest-by-brands?hex=$hex&brandIds=$brandsParam&limit=$limit&page=$page',
    );

    print('DEBUG: PaintMatchService - URL de la petición: ${url.toString()}');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print(
        'DEBUG: PaintMatchService - Código de respuesta: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Validar estructura de la respuesta
        print(
          'DEBUG: PaintMatchService - paints count: ${data['paints']?.length ?? 'null'}',
        );
        print('DEBUG: PaintMatchService - currentPage: ${data['currentPage']}');
        print('DEBUG: PaintMatchService - totalPages: ${data['totalPages']}');

        // Revisar el primer resultado
        if (data['paints'] != null && (data['paints'] as List).isNotEmpty) {
          final firstPaint = (data['paints'] as List).first;
          print(
            'DEBUG: PaintMatchService - Primer resultado: name=${firstPaint['name']}, hex=${firstPaint['hex']}',
          );
        }

        return {
          'paints': data['paints'] ?? [],
          'currentPage': data['currentPage'] ?? 1,
          'totalPages': data['totalPages'] ?? 1,
        };
      } else {
        print('DEBUG: PaintMatchService - Error body: ${response.body}');
        throw Exception(
          'Failed to fetch matching paints: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('DEBUG: PaintMatchService - Error en la petición: $e');
      rethrow;
    }
  }
}
