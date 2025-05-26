import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:miniature_paint_finder/services/palette_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/utils/env.dart';

class ColorSearchService {
  static final String baseUrl = '${Env.apiBaseUrl}';
  final PaletteService _paletteService = PaletteService();

  Future<void> saveColorSearch({
    required String token,
    required String name,
    required List<Map<String, dynamic>> paints,
    required String imagePath,
  }) async {
    try {
      // Paso 1: Subir la imagen
      final imageData = await _paletteService.uploadImage(imagePath, token);
      final imageId = imageData['id'];

      // Paso 2: Preparar y crear los picks de la imagen
      final colorData =
          paints.asMap().entries.map((entry) {
            final index = entry.key;
            final paint = entry.value;
            final color = Color(
              int.parse(paint['hex'].substring(1), radix: 16) + 0xFF000000,
            );
            return {
              'index': index,
              'hex_color': paint['hex'],
              'r': color.red,
              'g': color.green,
              'b': color.blue,
              'x_coord': '1.2',
              'y_coord': '1.1',
            };
          }).toList();

      final picks = await _paletteService.getImagePicks(
        imageId,
        token,
        colorData,
      );

      if (picks.isEmpty) {
        throw Exception('No se crearon picks para la imagen');
      }

      if (picks.length != paints.length) {
        throw Exception('Número de picks no coincide con número de pinturas');
      }

      // Paso 3: Crear la paleta
      final paletteData = await _paletteService.createPalette(name, token);
      final paletteId = paletteData['id'];

      // Paso 4: Agregar las pinturas a la paleta
      final paintsToSend = <Map<String, dynamic>>[];

      for (var i = 0; i < paints.length; i++) {
        final paint = paints[i];

        if (i < picks.length) {
          final pick = picks[i];
          final paintToSend = {
            'paint_id': paint['id'],
            'brand_id': paint['brand_id'],
            'image_color_picks_id': pick['id'],
          };
          paintsToSend.add(paintToSend);
        }
      }

      if (paintsToSend.isEmpty) {
        throw Exception('No hay pinturas válidas para agregar a la paleta');
      }

      await _paletteService.addPaintsToPalette(paletteId, paintsToSend, token);
    } catch (e) {
      rethrow;
    }
  }
}
