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

    debugPrint('✅ Imagen subida exitosamente');
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

    debugPrint('✅ Paleta creada exitosamente');
    return responseData['data'];
  }

  Future<void> addPaintsToPalette(
    String paletteId,
    List<Map<String, dynamic>> paints,
    String token,
  ) async {
    debugPrint('🎨 Agregando ${paints.length} pinturas a la paleta: $paletteId');
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