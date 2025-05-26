import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:miniature_paint_finder/models/most_used_paint.dart';
import 'package:miniature_paint_finder/utils/env.dart';

class PaletteService {
  static final String baseUrl = '${Env.apiBaseUrl}';

  Future<Map<String, dynamic>> uploadImage(
    String imagePath,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/image/upload');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'image_path': imagePath}),
    );

    final responseData = jsonDecode(response.body);

    if (responseData['executed'] == false) {
      throw Exception(responseData['message'] ?? 'Error uploading image');
    }

    return responseData['data'];
  }

  Future<Map<String, dynamic>> createPalette(String name, String token) async {
    final url = Uri.parse('$baseUrl/palettes');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );

    final responseData = jsonDecode(response.body);

    if (responseData['executed'] == false) {
      throw Exception(responseData['message'] ?? 'Error creating palette');
    }

    return responseData['data'];
  }

  Future<List<Map<String, dynamic>>> getImagePicks(
    String imageId,
    String token,
    List<Map<String, dynamic>> colorData,
  ) async {
    final url = Uri.parse('$baseUrl/image/$imageId/picks');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(colorData),
    );

    final responseData = jsonDecode(response.body);

    if (responseData['executed'] == false) {
      throw Exception(responseData['message'] ?? 'Error creating image picks');
    }

    if (responseData['data'] == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(responseData['data']);
  }

  Future<List<Map<String, dynamic>>> getAllPalettesNamesAndIds(
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/palettes/simple-list');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final responseData = jsonDecode(response.body);

    if (responseData['data'] == null) {
      return [];
    }

    final palettes = List<Map<String, dynamic>>.from(responseData['data']);

    return palettes
        .map((palette) => {'id': palette['id'], 'name': palette['name']})
        .toList();
  }

  Future<void> addPaintsToPalette(
    String paletteId,
    List<Map<String, dynamic>> paints,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/palettes/$paletteId/paints');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(paints),
    );

    final responseData = jsonDecode(response.body);

    if (responseData['executed'] == false) {
      throw Exception(
        responseData['message'] ?? 'Error adding paints to palette',
      );
    }
  }

  /// Adds a paint to a palette by its ID
  Future<Map<String, dynamic>> addPaintToPaletteById(
    String paletteName,
    String userId,
    String paintId,
    String brandId,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/palettes/add-paint');

      final paintData = {
        'palette_name': paletteName,
        'user_id': userId,
        'paint_id': paintId,
        'brand_id': brandId,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(paintData),
      );

      final responseData = jsonDecode(response.body);

      if (responseData['executed'] == false) {
        return {
          'executed': false,
          'message': responseData['message'] ?? 'Error adding paint to palette',
        };
      }

      return {'executed': true, 'data': responseData['data'] ?? {}};
    } catch (e) {
      return {'executed': false, 'message': 'Exception: $e'};
    }
  }

  /// Obtiene la lista de pinturas más usadas en todas las paletas
  Future<List<MostUsedPaint>> getMostUsedPaints(String token) async {
    final url = Uri.parse('$baseUrl/palettes/most-used-paints');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final responseData = jsonDecode(response.body);

    if (responseData['executed'] != true) {
      final msg = responseData['message'] ?? 'Error fetching most-used paints';
      throw Exception(msg);
    }

    final List<dynamic> rawList = responseData['data'] as List<dynamic>;
    return rawList
        .map((e) => MostUsedPaint.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
