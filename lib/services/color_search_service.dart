import 'dart:convert';
import 'package:http/http.dart' as http;

class ColorSearchService {
  static const String baseUrl = 'https://paints-api.reachu.io/api';

  Future<void> saveColorSearch({
    required String token,
    required String name,
    required List<Map<String, String>> paints,
  }) async {
    final url = Uri.parse('$baseUrl/color-search');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name, 'paints': paints}),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to save color search: ${response.statusCode} ${response.body}',
      );
    }
  }
}
