import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:miniature_paint_finder/models/paint.dart';

class PaintApiService {
  static const String baseUrl = 'https://paints-api.reachu.io/api';

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

    final uri = Uri.parse('$baseUrl/paint').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<Paint> paints = (data['paints'] as List)
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
  }

  Future<List<Map<String, dynamic>>> getBrands() async {
    final uri = Uri.parse('$baseUrl/brand');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error al cargar las marcas: ${response.statusCode}');
    }
  }
} 