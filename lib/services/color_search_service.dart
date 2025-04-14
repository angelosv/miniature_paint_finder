import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:miniature_paint_finder/services/palette_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    debugPrint('🎨 Pinturas a procesar: ${jsonEncode(paints)}');

    try {
      // Paso 1: Subir la imagen
      debugPrint('📤 Paso 1: Subiendo imagen...');
      final imageData = await _paletteService.uploadImage(imagePath, token);
      final imageId = imageData['id'];
      debugPrint('✅ Imagen subida con ID: $imageId');
      debugPrint('📦 Datos de imagen: ${jsonEncode(imageData)}');

      // Paso 2: Preparar y crear los picks de la imagen
      debugPrint('📤 Paso 2: Preparando datos de picks...');
      final colorData = paints.asMap().entries.map((entry) {
        final index = entry.key;
        final paint = entry.value;
        final color = Color(int.parse(paint['hex'].substring(1), radix: 16) + 0xFF000000);
        return {
          'index': index,
          'hex_color': paint['hex'],
          'r': color.red,
          'g': color.green,
          'b': color.blue,
          'x_coord': '1.2', // Coordenadas de ejemplo, deberían venir de la selección del usuario
          'y_coord': '1.1',
        };
      }).toList();
      
      debugPrint('🎨 Datos de colores preparados: ${jsonEncode(colorData)}');
      debugPrint('📤 Creando picks...');
      final picks = await _paletteService.getImagePicks(imageId, token, colorData);
      debugPrint('✅ Picks creados: ${picks.length}');
      debugPrint('📦 Datos de picks: ${jsonEncode(picks)}');

      if (picks.isEmpty) {
        debugPrint('❌ No se crearon picks para la imagen');
        throw Exception('No se crearon picks para la imagen');
      }

      if (picks.length != paints.length) {
        debugPrint('⚠️ Advertencia: Número de picks (${picks.length}) no coincide con número de pinturas (${paints.length})');
        debugPrint('   Picks: ${jsonEncode(picks)}');
        debugPrint('   Pinturas: ${jsonEncode(paints)}');
      }

      // Paso 3: Crear la paleta
      debugPrint('📤 Paso 3: Creando paleta...');
      final paletteData = await _paletteService.createPalette(name, token);
      final paletteId = paletteData['id'];
      debugPrint('✅ Paleta creada con ID: $paletteId');
      debugPrint('📦 Datos de paleta: ${jsonEncode(paletteData)}');

      // Paso 4: Agregar las pinturas a la paleta
      debugPrint('📤 Paso 4: Agregando pinturas a la paleta...');
      final paintsToSend = <Map<String, dynamic>>[];
      
      for (var i = 0; i < paints.length; i++) {
        final paint = paints[i];
        debugPrint('🎨 Procesando pintura $i:');
        debugPrint('   Pintura: ${jsonEncode(paint)}');
        
        if (i < picks.length) {
          final pick = picks[i];
          debugPrint('   Pick correspondiente: ${jsonEncode(pick)}');
          final paintToSend = {
            'paint_id': paint['id'],
            'brand_id': paint['brand_id'],
            'image_color_picks_id': pick['id'],
          };
          debugPrint('   Pintura a enviar: ${jsonEncode(paintToSend)}');
          paintsToSend.add(paintToSend);
        } else {
          debugPrint('⚠️ No hay pick disponible para la pintura en índice $i');
        }
      }

      if (paintsToSend.isEmpty) {
        debugPrint('❌ No hay pinturas válidas para agregar a la paleta');
        throw Exception('No hay pinturas válidas para agregar a la paleta');
      }

      debugPrint('🎨 Pinturas finales a enviar: ${jsonEncode(paintsToSend)}');
      final paintIds = paintsToSend
        .map((paint) => paint['id'] as String)
        .toList();
      await _paletteService.addPaintsToPalette(paletteId, paintIds);
      debugPrint('✅ Proceso completado exitosamente');
    } catch (e) {
      debugPrint('❌ Error en el proceso: $e');
      rethrow;
    }
  }
}
