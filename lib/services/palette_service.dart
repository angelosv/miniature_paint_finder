import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/palette.dart';
import '../config/api_config.dart';

class PaletteService {
  final String baseUrl = ApiConfig.baseUrl;

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

  Future<List<PaletteSimple>> getSimplePaletteList() async {
    try {
      final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
      
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/palettes/simple-list'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['executed'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((paletteSimple) => PaletteSimple.fromJson(paletteSimple))
              .toList();
        }
      }
      
      throw Exception('Failed to load palettes');
    } catch (e) {
      throw Exception('Error fetching palettes: $e');
    }
  }

  Future<void> addPaintsToPalette(String paletteId, List<Paint> paints) async {
    try {
      final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
      
      if (token == null) {
        throw Exception('No authentication token available');
      }

      debugPrint('🎨 Adding ${paints.length} paints to palette: $paletteId');
      debugPrint('📤 Data to send: ${jsonEncode(paints.map((p) => p.id).toList())}');

      final response = await http.post(
        Uri.parse('$baseUrl/palettes/$paletteId/paints'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(paints.map((p) => p.id).toList()),
      );

      debugPrint('📤 Add paints response: ${response.body}');
      final responseData = jsonDecode(response.body);

      if (responseData['executed'] == false) {
        debugPrint('❌ Error adding paints: ${responseData['message']}');
        throw Exception(responseData['message'] ?? 'Error adding paints to palette');
      }

      debugPrint('✅ Paints added successfully');
    } catch (e) {
      debugPrint('❌ Error in addPaintsToPalette: $e');
      throw Exception('Failed to add paints to palette: $e');
    }
  }
} 