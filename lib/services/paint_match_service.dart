// lib/services/paint_match_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class PaintMatchService {
  static const String baseUrl = 'https://paints-api.reachu.io/api';

  Future<Map<String, dynamic>> fetchMatchingPaints({
    required String token,
    required String hexColor,
    required List<String> brandIds,
    int limit = 10,
    int page = 1,
  }) async {
    final hex = hexColor.replaceAll('#', '');
    final brandsParam = brandIds.join(',');

    final url = Uri.parse(
      '$baseUrl/paint/closest-by-brands?hex=$hex&brandIds=$brandsParam&limit=$limit&page=$page',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'paints': data['paints'],
        'currentPage': data['currentPage'],
        'totalPages': data['totalPages'],
      };
    } else {
      throw Exception(
        'Failed to fetch matching paints: ${response.statusCode}',
      );
    }
  }
}
