import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:miniature_paint_finder/models/paint.dart';

class PaintApiService {
  static const String baseUrl = 'https://paints-api.reachu.io/api';

  // Flag para habilitar logs detallados
  final bool _enableDetailedLogs = true;

  // Método para imprimir logs
  void _log(String message) {
    if (_enableDetailedLogs) {
      debugPrint('🔵 PaintAPI: $message');
    }
  }

  Future<Map<String, dynamic>> getPaints({
    String? brandId,
    String? name,
    String? code,
    String? hex,
    int limit = 10,
    int? page,
  }) async {
    final queryParams = {
      if (brandId != null) 'brandId': brandId,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (hex != null) 'hex': hex,
      'limit': limit.toString(),
      if (page != null) 'page': page.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/paint',
    ).replace(queryParameters: queryParams);

    _log('📤 GET Request: $uri');
    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.get(uri);
      stopwatch.stop();

      _log('⏱️ Response time: ${stopwatch.elapsedMilliseconds}ms');
      _log('📥 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
}
