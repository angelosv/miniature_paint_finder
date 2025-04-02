import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:miniature_paint_finder/services/palette_service.dart';
import 'package:flutter/foundation.dart';

class ColorSearchService {
  static const String baseUrl = 'https://paints-api.reachu.io/api';
  final PaletteService _paletteService = PaletteService();

  Future<void> saveColorSearch({
    required String token,
    required String name,
    required List<Map<String, dynamic>> paints,
    required String imagePath,
  }) async {
    debugPrint('🚀 Iniciando proceso de guardado de paleta: $name');
    debugPrint('📝 Token: ${token.substring(0, 10)}...');
    debugPrint('🖼️ Ruta de imagen: $imagePath');
    debugPrint('🎨 Número de pinturas: ${paints.length}');

    try {
      // Paso 1: Subir la imagen
      debugPrint('📤 Paso 1: Subiendo imagen...');
      final imageData = await _paletteService.uploadImage(imagePath, token);
      final imageId = imageData['id'];
      debugPrint('✅ Imagen subida con ID: $imageId');

      // Paso 2: Crear la paleta
      debugPrint('📤 Paso 2: Creando paleta...');
      final paletteData = await _paletteService.createPalette(name, token);
      final paletteId = paletteData['id'];
      debugPrint('✅ Paleta creada con ID: $paletteId');

      // Paso 3: Agregar las pinturas a la paleta
      debugPrint('📤 Paso 3: Agregando pinturas a la paleta...');
      debugPrint('🔍 Estructura de la primera pintura: ${paints.first}');
      final paintsToSend = paints.map((paint) {
        debugPrint('🎨 Pintura a procesar: $paint');
        return {
          'paint_id': paint['id'],
          'brand_id': paint['brand_id'],
          'image_color_picks_id': imageId,
        };
      }).toList();
      debugPrint('🎨 Pinturas a enviar: ${paintsToSend.length}');

      await _paletteService.addPaintsToPalette(paletteId, paintsToSend, token);
      debugPrint('✅ Proceso completado exitosamente');
    } catch (e) {
      debugPrint('❌ Error en el proceso de guardado: $e');
      throw Exception('Failed to save color search: $e');
    }
  }
}
