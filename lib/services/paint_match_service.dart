// lib/services/paint_match_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:miniature_paint_finder/utils/env.dart';

class PaintMatchService {
  static final String baseUrl = '${Env.apiBaseUrl}';

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

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Validar estructura de la respuesta

        // Revisar el primer resultado
        if (data['paints'] != null && (data['paints'] as List).isNotEmpty) {
          final firstPaint = (data['paints'] as List).first;
        }

        return {
          'paints': data['paints'] ?? [],
          'currentPage': data['currentPage'] ?? 1,
          'totalPages': data['totalPages'] ?? 1,
        };
      } else {
        throw Exception(
          'Failed to fetch matching paints: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
