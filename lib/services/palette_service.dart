import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PaletteService {
  static const String baseUrl = 'https://paints-api.reachu.io/api';

  Future<Map<String, dynamic>> uploadImage(String imagePath, String token) async {
    debugPrint('🖼️ Subiendo imagen: $imagePath');
    final url = Uri.parse('$baseUrl/image/upload');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'image_path': imagePath}),
    );

    debugPrint('📤 Respuesta de subida de imagen: ${response.body}');
    final responseData = jsonDecode(response.body);

    if (responseData['executed'] == false) {
      debugPrint('❌ Error al subir imagen: ${responseData['message']}');
      throw Exception(responseData['message'] ?? 'Error uploading image');
    }

    debugPrint('✅ Imagen subida exitosamente con ID: ${responseData['data']['id']}');
    return responseData['data'];
  }

  Future<Map<String, dynamic>> createPalette(String name, String token) async {
    debugPrint('🎨 Creando paleta: $name');
    final url = Uri.parse('$baseUrl/palettes');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );

    debugPrint('📤 Respuesta de creación de paleta: ${response.body}');
    final responseData = jsonDecode(response.body);

    if (responseData['executed'] == false) {
      debugPrint('❌ Error al crear paleta: ${responseData['message']}');
      throw Exception(responseData['message'] ?? 'Error creating palette');
    }

    debugPrint('✅ Paleta creada exitosamente con ID: ${responseData['data']['id']}');
    return responseData['data'];
  }

  Future<List<Map<String, dynamic>>> getImagePicks(String imageId, String token, List<Map<String, dynamic>> colorData) async {
    debugPrint('🔍 Creando picks para la imagen: $imageId');
    final url = Uri.parse('$baseUrl/image/$imageId/picks');
    debugPrint('🌐 URL de picks: $url');
    debugPrint('🔑 Token usado: ${token.substring(0, 10)}...');
    debugPrint('🎨 Datos de colores a enviar: ${jsonEncode(colorData)}');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(colorData),
    );

    debugPrint('📤 Respuesta completa de picks:');
    debugPrint('📤 Status Code: ${response.statusCode}');
    debugPrint('📤 Headers: ${response.headers}');
    debugPrint('📤 Body: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (responseData['executed'] == false) {
      debugPrint('❌ Error al crear picks: ${responseData['message']}');
      throw Exception(responseData['message'] ?? 'Error creating image picks');
    }

    if (responseData['data'] == null) {
      debugPrint('⚠️ La respuesta no contiene datos de picks');
      return [];
    }

    final picks = List<Map<String, dynamic>>.from(responseData['data']);
    debugPrint('✅ Picks creados exitosamente:');
    for (var i = 0; i < picks.length; i++) {
      debugPrint('   Pick $i: ${picks[i]}');
    }
    return picks;
  }

  Future<List<Map<String, dynamic>>> getAllPalettesNamesAndIds(String token) async {
    final url = Uri.parse('$baseUrl/palettes/simple-list');
    debugPrint('🌐 URL de getAllPalettesNameAndId: $url');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    debugPrint('📤 Respuesta completa de getAllPalettesNameAndId:');
    debugPrint('📤 Status Code: ${response.statusCode}');
    debugPrint('📤 Headers: ${response.headers}');
    debugPrint('📤 Body: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (responseData['data'] == null) {
      debugPrint('⚠️ La respuesta no contiene datos de paletas');
      return [];
    }

    final palettes = List<Map<String, dynamic>>.from(responseData['data']);
    
    // Convertir los datos al formato esperado por el selector
    return palettes.map((palette) => {
      'id': palette['id'],
      'name': palette['name'],
    }).toList();
  }

  Future<void> addPaintsToPalette(
    String paletteId,
    List<Map<String, dynamic>> paints,
    String token,
  ) async {
    debugPrint('🎨 Agregando ${paints.length} pinturas a la paleta: $paletteId');
    debugPrint('📤 Datos a enviar: ${jsonEncode(paints)}');
    final url = Uri.parse('$baseUrl/palettes/$paletteId/paints');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(paints),
    );

    debugPrint('📤 Respuesta de agregar pinturas: ${response.body}');
    final responseData = jsonDecode(response.body);

    if (responseData['executed'] == false) {
      debugPrint('❌ Error al agregar pinturas: ${responseData['message']}');
      throw Exception(responseData['message'] ?? 'Error adding paints to palette');
    }

    debugPrint('✅ Pinturas agregadas exitosamente');
  }
} 