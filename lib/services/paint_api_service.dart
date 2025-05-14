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

    print('📤 GET Request: $uri');
    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.get(uri);
      stopwatch.stop();

      _log('⏱️ Response time: ${stopwatch.elapsedMilliseconds}ms');
      _log('📥 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Log completo para inspección
        //_logJson('Respuesta', data);

        // Log detallado de la primera pintura si existe
        if (data['paints'] != null && (data['paints'] as List).isNotEmpty) {
          final firstPaintJson = (data['paints'] as List)[0];
          // _logJson('Ejemplo de pintura', firstPaintJson);

          // Log específico para campos relacionados con imágenes
          if (firstPaintJson.containsKey('imageUrl')) {
            _log(
              '🖼️ Campo imageUrl encontrado: ${firstPaintJson['imageUrl']}',
            );
          }
          if (firstPaintJson.containsKey('image')) {
            _log('🖼️ Campo image encontrado: ${firstPaintJson['image']}');
          }
          if (firstPaintJson.containsKey('brand_logo')) {
            _log(
              '🏷️ Campo brand_logo encontrado: ${firstPaintJson['brand_logo']}',
            );
          }
          if (firstPaintJson.containsKey('brandLogo')) {
            _log(
              '🏷️ Campo brandLogo encontrado: ${firstPaintJson['brandLogo']}',
            );
          }
        }

        final List<Paint> paints =
            (data['paints'] as List)
                .map((paintJson) => Paint.fromJson(paintJson))
                .toList();

        _log(
          '✅ Received ${paints.length} paints (Page ${data['currentPage']} of ${data['totalPages']})',
        );
        _log('📊 Total paints in database: ${data['totalPaints']}');

        return {
          'paints': paints,
          'currentPage': data['currentPage'],
          'totalPaints': data['totalPaints'],
          'totalPages': data['totalPages'],
          'limit': data['limit'],
        };
      } else {
        _log('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Error al cargar las pinturas: ${response.statusCode}');
      }
    } catch (e) {
      _log('🔴 Exception: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBrands() async {
    final uri = Uri.parse('$baseUrl/brand');

    _log('📤 GET Request: $uri');
    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.get(uri);
      stopwatch.stop();

      _log('⏱️ Response time: ${stopwatch.elapsedMilliseconds}ms');
      _log('📥 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Log de ejemplo de marca
        if (data.isNotEmpty) {
          _logJson('Ejemplo de marca', data[0] as Map<String, dynamic>);
        }

        _log('✅ Received ${data.length} brands');
        return List<Map<String, dynamic>>.from(data);
      } else {
        _log('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Error al cargar las marcas: ${response.statusCode}');
      }
    } catch (e) {
      _log('🔴 Exception: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final uri = Uri.parse('$baseUrl/paint/category');
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(uri);
      stopwatch.stop();

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);
        final List<dynamic> data = decoded['data'];
        return List<Map<String, dynamic>>.from(data);
      } else {
        _log('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception(
          'Error al cargar las categorias: ${response.statusCode}',
        );
      }
    } catch (e) {
      _log('🔴 Exception: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> submitPaint(PaintSubmit item) async {
    try {
      print('submitPaint');
      final url = Uri.parse('${Env.apiBaseUrl}/paint/pending-paint-submissions');
      print('submitPaint URL: $url');
      print('submitPaint: ${item.toJson()}');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(item.toJson()),
      );
      print('submitPaint response.statusCode: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;  
      } else {
        return false;
      }
    } catch (e) {
      print('Error Submitting paint in API: $e');
      return false;
    }
  }
}
