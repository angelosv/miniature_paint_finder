import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:miniature_paint_finder/models/paint_brand.dart';

class PaintBrandService {
  static const String baseUrl = 'https://paints-api.reachu.io/api';

  Future<List<PaintBrand>> getPaintBrands() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/brand'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PaintBrand.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load paint brands: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching paint brands: $e');
      throw Exception('Failed to load paint brands: $e');
    }
  }
} 