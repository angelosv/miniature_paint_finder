import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/utils/env.dart';
import 'package:miniature_paint_finder/models/paint_submit.dart';

class PaintApiService {
  static final String baseUrl = '${Env.apiBaseUrl}';

  // Flag para habilitar logs detallados
  final bool _enableDetailedLogs = false;

  // Método para imprimir logs
  void _log(String message) {
    if (_enableDetailedLogs) {
      debugPrint('🔵 PaintAPI: $message');
    }
  }

  // Método para imprimir logs largos con formato JSON
  void _logJson(String prefix, Map<String, dynamic> json) {
    if (_enableDetailedLogs) {
      try {
        const JsonEncoder encoder = JsonEncoder.withIndent('  ');
        final String prettyJson = encoder.convert(json);
        // Dividir por líneas para mejor legibilidad en la consola
        final lines = prettyJson.split('\n');
        debugPrint('🟢 PaintAPI $prefix JSON:');
        for (var line in lines) {
          debugPrint('🟢 $line');
        }
      } catch (e) {
        debugPrint('🔴 PaintAPI: Error al formatear JSON: $e');
        debugPrint('🔴 PaintAPI: JSON sin formato: $json');
      }
    }
  }

  Future<Map<String, dynamic>> getPaints({
    String? category,
    String? brandId,
    String? name,
    String? code,
    String? hex,
    int limit = 10,
    int? page,
  }) async {
    final queryParams = {
      if (category != null && category != 'All') 'category': category,
      if (brandId != null && brandId != 'All' && brandId != '')
        'brandId': brandId,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (hex != null) 'hex': hex,
      'limit': limit.toString(),
      if (page != null) 'page': page.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/paint',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Paint> paints =
            (data['paints'] as List)
                .map((paintJson) => Paint.fromJson(paintJson))
                .toList();

        return {
          'paints': paints,
          'currentPage': data['currentPage'],
          'totalPaints': data['totalPaints'],
          'totalPages': data['totalPages'],
          'limit': data['limit'],
        };
      } else {
        throw Exception('Error al cargar las pinturas: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBrands() async {
    final uri = Uri.parse('$baseUrl/brand');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final processedData =
            data.map((brand) {
              final Map<String, dynamic> processedBrand =
                  Map<String, dynamic>.from(brand as Map<String, dynamic>);

              if (processedBrand.containsKey('paintCount')) {
                processedBrand['paint_count'] = processedBrand['paintCount'];
              } else if (!processedBrand.containsKey('paint_count')) {
                if (processedBrand.containsKey('paints_count')) {
                  processedBrand['paint_count'] =
                      processedBrand['paints_count'];
                } else if (processedBrand.containsKey('count')) {
                  processedBrand['paint_count'] = processedBrand['count'];
                } else {
                  processedBrand['paint_count'] = 0;
                }
              }

              if (processedBrand['paint_count'] is! int) {
                processedBrand['paint_count'] =
                    int.tryParse(processedBrand['paint_count'].toString()) ?? 0;
              }

              return processedBrand;
            }).toList();

        return processedData;
      } else {
        throw Exception('Error al cargar las marcas: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final uri = Uri.parse('$baseUrl/paint/category');
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);
        final List<dynamic> data = decoded['data'];
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
          'Error al cargar las categorias: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> submitPaint(PaintSubmit item) async {
    try {
      final url = Uri.parse(
        '${Env.apiBaseUrl}/paint/pending-paint-submissions',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(item.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
