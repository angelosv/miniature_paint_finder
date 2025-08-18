import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:http/http.dart' as http;
import 'package:miniature_paint_finder/utils/env.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miniature_paint_finder/services/brand_service_manager.dart';

/// Tipo de entrada de inventario
enum InventoryEntryType {
  /// Pintura nueva/sin usar
  new_paint,

  /// Pintura usada parcialmente
  used,

  /// Pintura casi vacía
  almost_empty,
}

/// Servicio para gestionar las operaciones relacionadas con pinturas
class PaintService {
  /// Lista de pinturas en inventario
  Map<String, Map<String, dynamic>> _inventory = {};

  /// Lista de pinturas en wishlist
  Map<String, Map<String, dynamic>> _wishlist = {};

  /// Paletas del usuario
  List<Palette> _userPalettes = [];

  /// Servicio de marcas
  final BrandServiceManager _brandManager = BrandServiceManager();

  /// Paint cache storage key
  static const String _CACHE_KEY = 'paint_cache';

  /// Last cache update timestamp key
  static const String _LAST_CACHE_UPDATE_KEY = 'last_cache_update';

  /// Constructor
  PaintService() {
    _loadDemoData();
    _initializeBrands();
  }

  /// Inicializa las marcas oficiales
  void _initializeBrands() {
    _brandManager.initialize().then((success) {
      if (!success) {
        // No se pudieron inicializar las marcas oficiales
      }
    });
  }

  /// Carga datos de demostración para pruebas
  void _loadDemoData() {
    // Agregar algunas pinturas al inventario para demo
    final samplePaints = SampleData.getPaints();
    for (int i = 0; i < samplePaints.length; i += 3) {
      final paint = samplePaints[i];
      _inventory[paint.id] = {
        'quantity': (i % 5) + 1,
        'note': i % 2 == 0 ? 'Demo note for ${paint.name}' : null,
        'addedAt': DateTime.now().subtract(Duration(days: i)),
        'type': InventoryEntryType.values[i % 3].toString(),
      };
    }

    // Agregar algunas pinturas a la wishlist para demo
    for (int i = 1; i < samplePaints.length; i += 4) {
      final paint = samplePaints[i];
      _wishlist[paint.id] = {
        'isPriority': i % 2 == 0,
        'addedAt': DateTime.now().subtract(Duration(days: i)),
      };
    }

    // Usar las paletas de muestra
    _userPalettes = SampleData.getPalettes();
  }

  /// Helper method to determine brand_id consistently
  String _determineBrandIdForPaint(Paint paint) {
    final brandId = paint.brandId;
    if (brandId == null || brandId.isEmpty) {
      return _brandManager.determineBrandIdForPaint(paint);
    }
    return brandId;
  }

  /// Verifica si una pintura está en el inventario
  bool isInInventory(String paintId) {
    return _inventory.containsKey(paintId);
  }

  /// Obtiene la cantidad de una pintura en el inventario
  int? getInventoryQuantity(String paintId) {
    return _inventory[paintId]?['quantity'] as int?;
  }

  /// Verifica si una pintura está en la wishlist
  bool isInWishlist(String paintId) {
    return _wishlist.containsKey(paintId);
  }

  /// Obtiene las paletas que contienen una pintura específica
  List<Palette> getPalettesContainingPaint(String paintId) {
    // Obtener las paletas del usuario
    final userPalettes = getUserPalettes();

    // Filtrar las paletas que realmente contienen la pintura
    return userPalettes.where((palette) {
      // Verificar si la paleta tiene selecciones de pintura
      if (palette.paintSelections == null) return false;

      // Buscar si la pintura está en las selecciones
      return palette.paintSelections!.any(
        (selection) => selection.paintId == paintId,
      );
    }).toList();
  }

  /// Obtiene las paletas del usuario
  List<Palette> getUserPalettes() {
    return _userPalettes;
  }

  /// Agrega una pintura al inventario
  Future<bool> addToInventory(
    Paint paint,
    int quantity, {
    String? note,
    InventoryEntryType type = InventoryEntryType.new_paint,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      final token = await user.getIdToken();
      final brandId = _determineBrandIdForPaint(paint);

      final url = Uri.parse('${Env.apiBaseUrl}/inventory');

      final body = {
        'brand_id': brandId,
        'paint_id': paint.id,
        'quantity': quantity,
        'notes': note ?? '',
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _inventory[paint.id] = {
          'quantity': quantity,
          'note': note,
          'addedAt': DateTime.now(),
          'type': InventoryEntryType.new_paint.toString(),
        };
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Actualiza una pintura en el inventario
  Future<bool> updateInventory(
    Paint paint,
    int quantity, {
    required String inventoryId,
    String? note,
    InventoryEntryType? type,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      final token = await user.getIdToken();
      final url = Uri.parse('${Env.apiBaseUrl}/inventory/$inventoryId');

      final Map<String, dynamic> body = {'quantity': quantity};

      if (note != null && note.trim().isNotEmpty) {
        body['notes'] = note;
      }

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        _inventory[paint.id] ??= {};
        final entry = _inventory[paint.id]!;

        entry['quantity'] = quantity;
        entry['updatedAt'] = DateTime.now();

        if (note != null && note.trim().isNotEmpty) {
          entry['note'] = note;
        }

        if (type != null) {
          entry['type'] = type.toString();
        }

        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Agrega una pintura a la wishlist
  Future<bool> addToWishlist(Paint paint, bool isPriority) async {
    // Simulamos una operación asíncrona
    await Future.delayed(const Duration(milliseconds: 300));

    _wishlist[paint.id] = {'isPriority': isPriority, 'addedAt': DateTime.now()};

    return true;
  }

  /// Elimina una pintura de la wishlist
  Future<bool> removeFromWishlist(
    String paintId,
    String _id,
    String token,
  ) async {
    final baseUrl = '${Env.apiBaseUrl}';
    final url = Uri.parse('$baseUrl/wishlist/$_id');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (_wishlist.containsKey(paintId)) {
          _wishlist.remove(paintId);
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza la prioridad de una pintura en la wishlist
  Future<bool> updateWishlistPriority(
    String paintId,
    String wishlistId,
    bool isPriority,
    String token, [
    int priorityLevel = 0,
  ]) async {
    final baseUrl = '${Env.apiBaseUrl}';
    final url = Uri.parse('$baseUrl/wishlist/$wishlistId');

    final int priorityValue = priorityLevel.clamp(0, 5);
    final requestBody = {'type': 'favorite', 'priority': priorityValue};

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        if (_wishlist.containsKey(paintId)) {
          _wishlist[paintId]!['isPriority'] = isPriority;
          _wishlist[paintId]!['priority'] = priorityValue;
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene todas las pinturas de la wishlist
  Future<List<Map<String, dynamic>>> getWishlistPaints(String token) async {
    final baseUrl = '${Env.apiBaseUrl}';
    final url = Uri.parse('$baseUrl/wishlist');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch wishlist (${response.statusCode}): ${response.body}',
        );
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);
      final List<dynamic> wishlist = jsonData['whitelist'] ?? [];

      final List<Map<String, dynamic>> result = [];
      int skippedCount = 0;
      int processedCount = 0;

      for (final item in wishlist) {
        if (item == null) {
          skippedCount++;
          continue;
        }

        try {
          bool isDirectFormat =
              item['paint'] == null && item['paint_id'] != null;
          String paintId =
              isDirectFormat ? item['paint_id'] : item['paint']?['code'];
          String brandId =
              isDirectFormat ? item['brand_id'] : item['brand']?['name'];

          if (paintId == null || brandId == null) {
            skippedCount++;
            continue;
          }

          if (isDirectFormat) {
            final createdAt = item['created_at'];

            final Paint paint = Paint.fromHex(
              id: paintId,
              name: _getPaintNameFromId(paintId),
              brand: _formatBrandId(brandId),
              hex: '#9c27b0',
              set: '',
              code: paintId,
              category: '',
            );

            DateTime addedAt;
            try {
              addedAt = DateTime.fromMillisecondsSinceEpoch(
                createdAt['_seconds'] * 1000,
              );
            } catch (e) {
              addedAt = DateTime.now();
            }

            result.add({
              'id': item['id'] ?? 'unknown-id',
              'paint': paint,
              'isPriority': item['priority'] != null,
              'priority': item['priority'],
              'addedAt': addedAt,
              'brand': item['brand'],
            });

            processedCount++;
          } else if (item['paint'] != null && item['brand'] != null) {
            final paintJson = item['paint'];
            final brandJson = item['brand'];
            final createdAt = item['created_at'];

            final hexColor =
                paintJson['hex'].startsWith('#')
                    ? paintJson['hex'].substring(1)
                    : paintJson['hex'];
            final r = int.parse(hexColor.substring(0, 2), radix: 16);
            final g = int.parse(hexColor.substring(2, 4), radix: 16);
            final b = int.parse(hexColor.substring(4, 6), radix: 16);

            final paint = Paint(
              id: paintJson['code'],
              name: paintJson['name'],
              brand: brandJson['name'],
              hex: paintJson['hex'],
              set: paintJson['set'] ?? 'Unknown',
              code: paintJson['code'],
              r: r,
              g: g,
              b: b,
              category: paintJson['set'] ?? 'Unknown',
              isMetallic: false,
              isTransparent: false,
            );

            result.add({
              'id': item['id'] ?? 'unknown-id',
              'paint': paint,
              'isPriority': item['priority'] != null,
              'priority': item['priority'],
              'addedAt': DateTime.fromMillisecondsSinceEpoch(
                createdAt['_seconds'] * 1000,
              ),
              'brand': item['brand'],
              'palettes': item['palettes'],
            });

            processedCount++;
          } else {
            skippedCount++;
          }
        } catch (e) {
          skippedCount++;
        }
      }

      result.sort((a, b) {
        final aPriority = a['priority'] ?? 9999;
        final bPriority = b['priority'] ?? 9999;

        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }

        return (b['addedAt'] as DateTime).compareTo(a['addedAt'] as DateTime);
      });

      return result;
    } catch (e) {
      return [];
    }
  }

  /// Obtener un nombre de pintura a partir de un ID
  String _getPaintNameFromId(String paintId) {
    // Convertir IDs como "violet-volt-764287" a "Violet Volt"
    try {
      // Convertir guiones a espacios y capitalizar cada palabra
      final namePart = paintId
          .split('-')
          .where(
            (part) =>
                // Filtrar partes que parecen ser números/códigos
                !RegExp(r'^[0-9]+$').hasMatch(part),
          )
          .map(
            (part) =>
                // Capitalizar primera letra de cada palabra
                part.substring(0, 1).toUpperCase() + part.substring(1),
          )
          .join(' ');

      return namePart.isNotEmpty ? namePart : paintId;
    } catch (e) {
      return paintId; // Devolver el ID si hay algún error
    }
  }

  /// Formatear un ID de marca a un nombre más legible
  String _formatBrandId(String brandId) {
    try {
      // Remplazar guiones bajos por espacios
      return brandId.replaceAll('_', ' ');
    } catch (e) {
      return brandId;
    }
  }

  /// Agrega una pintura a una paleta
  Future<bool> addToPalette(Paint paint, Palette palette) async {
    // Simulamos una operación asíncrona
    await Future.delayed(const Duration(milliseconds: 300));

    // En una implementación real, agregaríamos la pintura a la paleta
    // Aquí solo simulamos éxito
    return true;
  }

  /// Busca equivalencias de una pintura en otras marcas
  Future<List<Paint>> findEquivalents(Paint paint) async {
    // Simulamos una operación asíncrona
    await Future.delayed(const Duration(milliseconds: 500));

    // Para demo, devolvemos pinturas con colores similares
    final paintColor = int.parse(paint.hex.substring(1), radix: 16);

    return SampleData.getPaints()
        .where((p) {
          if (p.id == paint.id) return false;
          if (p.brand == paint.brand) return false;

          final pColor = int.parse(p.hex.substring(1), radix: 16);
          final diff = (paintColor - pColor).abs();

          // Aceptamos pinturas con una diferencia de color menor a cierto umbral
          return diff < 1000000;
        })
        .take(5) // Limitamos a 5 resultados
        .toList();
  }

  /// Crea una nueva paleta a través del API
  Future<Map<String, dynamic>> createPaletteViaAPI(
    String name,
    List<Color> colors,
    String token,
  ) async {
    try {
      final baseUrl = '${Env.apiBaseUrl}';
      final url = Uri.parse('$baseUrl/palettes');

      List<Map<String, dynamic>> colorData =
          colors.map((color) {
            final String hex = '#${color.value.toRadixString(16).substring(2)}';
            final r = color.red;
            final g = color.green;
            final b = color.blue;

            return {'hex': hex, 'r': r, 'g': g, 'b': b};
          }).toList();

      final Map<String, dynamic> requestBody = {
        'name': name,
        'colors': colorData,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      Map<String, dynamic> responseData = {};
      if (response.body != null && response.body.isNotEmpty) {
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          responseData = {'error': 'Invalid JSON response: ${response.body}'};
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String paletteId = responseData['id'] ?? 'unknown-id';

        final palette = Palette(
          id: paletteId,
          name: name,
          imagePath: 'assets/images/placeholder.jpg',
          colors: colors,
          createdAt: DateTime.now(),
        );

        _userPalettes.add(palette);

        return {
          'success': true,
          'id': paletteId,
          'message': 'Palette created successfully',
          'palette': palette,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create palette (${response.statusCode})',
          'error': responseData,
          'raw_response': response.body,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Método de prueba de integración para diagnóstico
  Future<Map<String, dynamic>> testPaletteAndWishlistIntegration(
    Paint paint,
    String token,
  ) async {
    try {
      // 1. Verificar la estructura actual de wishlist
      await debugWishlistData(token);

      // 2. Verificar la estructura actual de paletas
      await debugPaletteData(token);

      // 3. Crear una nueva paleta para pruebas
      final color = Color(
        int.parse(paint.hex.substring(1), radix: 16) + 0xFF000000,
      );
      final createPaletteResult = await createPaletteViaAPI(
        'Test Palette ${DateTime.now().millisecondsSinceEpoch}',
        [color],
        token,
      );

      if (!createPaletteResult['success']) {
        return {
          'success': false,
          'message': 'Error creating test palette',
          'error': createPaletteResult,
        };
      }

      final String paletteId = createPaletteResult['id'];

      // 4. Simular añadir una pintura a la paleta para ver qué datos se enviarían
      final simulationResult = await debugSavePaintToPalette(
        paint,
        paletteId,
        token,
      );

      // 5. Añadir la pintura a la paleta
      final addToPaletteResult = await addPaintToPalette(
        paint,
        paletteId,
        token,
      );

      // 6. Intentar añadir la pintura a la wishlist
      final addToWishlistResult = await addToWishlistDirect(
        paint,
        3,
        token.split(' ')[1],
      );

      return {
        'success': true,
        'create_palette_result': createPaletteResult,
        'simulation_result': simulationResult,
        'add_to_palette_result': addToPaletteResult,
        'add_to_wishlist_result': addToWishlistResult,
        'message': 'Test de integración completado',
        'palette_id': paletteId,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error en test de integración: $e'};
    }
  }

  /// Función para diagnosticar y corregir problemas con los brand_id en una paleta existente
  Future<Map<String, dynamic>> diagnosePaletteItemBrands(
    String paletteId,
    String token,
  ) async {
    try {
      final baseUrl = '${Env.apiBaseUrl}';

      // 1. Primero, obtenemos los datos actuales de la paleta
      final url = Uri.parse('$baseUrl/palettes/$paletteId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message':
              'Error al obtener datos de la paleta: ${response.statusCode}',
          'raw_response': response.body,
        };
      }

      final data = json.decode(response.body);

      // 2. Analizar las pinturas de la paleta
      if (!data.containsKey('data') ||
          !data['data'].containsKey('palettes_paints')) {
        return {
          'success': false,
          'message': 'Formato de datos de paleta incorrecto',
          'raw_response': data,
        };
      }

      final List paletteItems = data['data']['palettes_paints'];

      // Lista para almacenar los problemas encontrados
      final List<Map<String, dynamic>> itemsWithProblems = [];

      // 3. Verificar cada pintura
      for (final item in paletteItems) {
        final String paintId = item['paint_id'];
        final String currentBrandId = item['brand_id'];

        // Obtener datos completos de la pintura
        final Paint? paintResult = await _getPaintDetailsById(paintId);
        if (paintResult == null) {
          continue;
        }

        final Paint paint = paintResult;

        // Determinar el brand_id correcto según nuestra lógica
        final String correctBrandId = _determineBrandIdForPaint(paint);

        // Comprobar si hay discrepancia
        if (currentBrandId != correctBrandId) {
          itemsWithProblems.add({
            'item_id': item['id'],
            'paint_id': paintId,
            'current_brand_id': currentBrandId,
            'correct_brand_id': correctBrandId,
            'paint_name': paint.name,
            'paint_brand': paint.brand,
            'paint_set': paint.set,
          });
        }
      }

      return {
        'success': true,
        'palette_id': paletteId,
        'total_items': paletteItems.length,
        'items_with_problems': itemsWithProblems,
        'message':
            itemsWithProblems.isEmpty
                ? 'No se encontraron problemas de brand_id'
                : 'Se encontraron ${itemsWithProblems.length} problemas de brand_id',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error durante el diagnóstico: $e'};
    }
  }

  /// Helper para obtener detalles de una pintura por su ID
  Future<Paint?> _getPaintDetailsById(String paintId) async {
    try {
      // Aquí se podría implementar una llamada al API
      // Por ahora, creamos un Paint básico con los datos mínimos

      // Para pinturas de Army Painter con patrón de ID específico
      if (paintId.contains('-brown-') ||
          paintId.contains('-green-') ||
          paintId.contains('-blue-') ||
          paintId.contains('-red-') ||
          paintId.contains('-purple-') ||
          paintId.startsWith('husk-')) {
        return Paint.fromHex(
          id: paintId,
          name: 'Unknown Paint',
          brand: 'The Army Painter',
          hex: '#CCCCCC',
          set: 'Warpaints',
          code: paintId,
          category: 'Warpaints',
        );
      }

      // Pinturas de AK Interactive
      if (paintId.startsWith('AK')) {
        return Paint.fromHex(
          id: paintId,
          name: 'Unknown Paint',
          brand: 'AK Interactive',
          hex: '#CCCCCC',
          set: 'AK Interactive',
          code: paintId,
          category: 'AK',
        );
      }

      // Pinturas de Vallejo
      if (paintId.startsWith('VGC') || paintId.startsWith('VMC')) {
        return Paint.fromHex(
          id: paintId,
          name: 'Unknown Paint',
          brand: 'Vallejo',
          hex: '#CCCCCC',
          set: 'Vallejo',
          code: paintId,
          category: 'Vallejo',
        );
      }

      // Para otros IDs, devolvemos genéricos
      return Paint.fromHex(
        id: paintId,
        name: 'Unknown Paint',
        brand: 'Unknown Brand',
        hex: '#CCCCCC',
        set: 'Unknown Set',
        code: paintId,
        category: 'Unknown',
      );
    } catch (e) {
      return null;
    }
  }

  /// Función para corregir específicamente los problemas de Army Painter en una paleta
  Future<Map<String, dynamic>> fixArmyPainterInPalette(
    String paletteId,
    String token,
  ) async {
    try {
      final baseUrl = '${Env.apiBaseUrl}';

      // 1. Primero, obtenemos los datos actuales de la paleta
      final getUrl = Uri.parse('$baseUrl/palettes/$paletteId');

      final getResponse = await http.get(
        getUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (getResponse.statusCode != 200) {
        return {
          'success': false,
          'message':
              'Error al obtener datos de la paleta: ${getResponse.statusCode}',
          'raw_response': getResponse.body,
        };
      }

      final data = json.decode(getResponse.body);

      // 2. Analizar las pinturas de la paleta
      if (!data.containsKey('data') ||
          !data['data'].containsKey('palettes_paints')) {
        return {
          'success': false,
          'message': 'Formato de datos de paleta incorrecto',
          'raw_response': data,
        };
      }

      final List paletteItems = data['data']['palettes_paints'];

      // Lista para almacenar las pinturas que se van a corregir
      final List<Map<String, dynamic>> itemsToFix = [];

      // 3. Identificar pinturas de Army Painter con brand_id incorrecto
      for (final item in paletteItems) {
        final String paintId = item['paint_id'];
        final String currentBrandId = item['brand_id'];
        final String itemId = item['id'];

        // Verificar si es pintura de Army Painter con brand_id incorrecto
        bool isArmyPainter = false;

        // Comprobar por set (si está disponible)
        if (item.containsKey('paint') && item['paint'] != null) {
          final paintData = item['paint'];
          if (paintData.containsKey('set') &&
              paintData['set'].toString().toLowerCase().contains('warpaint')) {
            isArmyPainter = true;
          }
        }

        // Comprobar por ID de pintura
        if (paintId.contains('-brown-') ||
            paintId.contains('-green-') ||
            paintId.contains('-blue-') ||
            paintId.contains('-red-') ||
            paintId.contains('-purple-') ||
            paintId.startsWith('husk-')) {
          isArmyPainter = true;
        }

        // Si es de Army Painter pero no tiene el brand_id correcto
        if (isArmyPainter && currentBrandId != 'Army_Painter') {
          itemsToFix.add({
            'id': itemId,
            'paint_id': paintId,
            'current_brand_id': currentBrandId,
          });
        }
      }

      // 4. Corregir las pinturas identificadas
      final List<Map<String, dynamic>> fixResults = [];

      if (itemsToFix.isEmpty) {
        return {
          'success': true,
          'message': 'No se encontraron pinturas que corregir',
          'items_to_fix': itemsToFix,
        };
      }

      for (final item in itemsToFix) {
        final itemId = item['id'];
        final updateUrl = Uri.parse(
          '$baseUrl/palettes/$paletteId/paints/$itemId',
        );

        // Preparar los datos para actualizar
        final updateBody = {'brand_id': 'Army_Painter'};

        try {
          final updateResponse = await http.patch(
            updateUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(updateBody),
          );

          Map<String, dynamic> resultData = {
            'id': itemId,
            'success':
                updateResponse.statusCode == 200 ||
                updateResponse.statusCode == 201,
            'status_code': updateResponse.statusCode,
          };

          if (updateResponse.body.isNotEmpty) {
            try {
              resultData['response'] = json.decode(updateResponse.body);
            } catch (e) {
              resultData['raw_response'] = updateResponse.body;
            }
          }

          fixResults.add(resultData);
        } catch (e) {
          fixResults.add({
            'id': itemId,
            'success': false,
            'error': e.toString(),
          });
        }
      }

      // 5. Preparar respuesta
      final int successCount =
          fixResults.where((r) => r['success'] == true).length;

      return {
        'success': true,
        'message':
            'Se corrigieron $successCount de ${itemsToFix.length} pinturas',
        'items_fixed': fixResults,
        'palette_id': paletteId,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error durante la reparación: $e'};
    }
  }

  /// Repara problemas de marcas en paletas usando la lista oficial
  Future<Map<String, dynamic>> repairPaletteBrandsWithOfficialList(
    String paletteId,
    String token,
  ) async {
    try {
      // 0. Asegurar que tenemos las marcas oficiales cargadas
      if (!_brandManager.isLoaded) {
        final loaded = await loadOfficialBrands();
        if (!loaded) {
          return {
            'success': false,
            'message': 'No se pudieron cargar las marcas oficiales',
          };
        }
      }

      final baseUrl = '${Env.apiBaseUrl}';

      // 1. Obtener datos de la paleta
      final getUrl = Uri.parse('$baseUrl/palettes/$paletteId');

      // 2. Obtener datos de la paleta
      final getResponse = await http.get(
        getUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (getResponse.statusCode != 200) {
        return {
          'success': false,
          'message':
              'Error al obtener datos de la paleta: ${getResponse.statusCode}',
          'raw_response': getResponse.body,
        };
      }

      final data = json.decode(getResponse.body);

      // 3. Verificar si la paleta contiene pinturas de Army Painter
      if (!data.containsKey('data') ||
          !data['data'].containsKey('palettes_paints')) {
        return {
          'success': false,
          'message': 'Formato de datos de paleta incorrecto',
          'raw_response': data,
        };
      }

      final List paletteItems = data['data']['palettes_paints'];

      // Lista para almacenar las pinturas que se van a corregir
      final List<Map<String, dynamic>> itemsToFix = [];

      // 4. Identificar pinturas de Army Painter con brand_id incorrecto
      for (final item in paletteItems) {
        final String paintId = item['paint_id'];
        final String currentBrandId = item['brand_id'];
        final String itemId = item['id'];

        // Verificar si es pintura de Army Painter con brand_id incorrecto
        bool isArmyPainter = false;

        // Comprobar por set (si está disponible)
        if (item.containsKey('paint') && item['paint'] != null) {
          final paintData = item['paint'];
          if (paintData.containsKey('set') &&
              paintData['set'].toString().toLowerCase().contains('warpaint')) {
            isArmyPainter = true;
          }
        }

        // Comprobar por ID de pintura
        if (paintId.contains('-brown-') ||
            paintId.contains('-green-') ||
            paintId.contains('-blue-') ||
            paintId.contains('-red-') ||
            paintId.contains('-purple-') ||
            paintId.startsWith('husk-')) {
          isArmyPainter = true;
        }

        // Si es de Army Painter pero no tiene el brand_id correcto
        if (isArmyPainter && currentBrandId != 'Army_Painter') {
          itemsToFix.add({
            'id': itemId,
            'paint_id': paintId,
            'current_brand_id': currentBrandId,
          });
        }
      }

      // 5. Corregir las pinturas identificadas
      final List<Map<String, dynamic>> fixResults = [];

      if (itemsToFix.isEmpty) {
        return {
          'success': true,
          'message': 'No se encontraron pinturas que corregir',
          'items_to_fix': itemsToFix,
        };
      }

      for (final item in itemsToFix) {
        final itemId = item['id'];
        final updateUrl = Uri.parse(
          '$baseUrl/palettes/$paletteId/paints/$itemId',
        );

        // Preparar los datos para actualizar
        final updateBody = {'brand_id': 'Army_Painter'};

        try {
          final updateResponse = await http.patch(
            updateUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(updateBody),
          );

          Map<String, dynamic> resultData = {
            'id': itemId,
            'success':
                updateResponse.statusCode == 200 ||
                updateResponse.statusCode == 201,
            'status_code': updateResponse.statusCode,
          };

          if (updateResponse.body.isNotEmpty) {
            try {
              resultData['response'] = json.decode(updateResponse.body);
            } catch (e) {
              resultData['raw_response'] = updateResponse.body;
            }
          }

          fixResults.add(resultData);
        } catch (e) {
          fixResults.add({
            'id': itemId,
            'success': false,
            'error': e.toString(),
          });
        }
      }

      // 6. Preparar respuesta
      final int successCount =
          fixResults.where((r) => r['success'] == true).length;

      return {
        'success': true,
        'message':
            'Se corrigieron $successCount de ${itemsToFix.length} pinturas',
        'items_fixed': fixResults,
        'palette_id': paletteId,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error durante la reparación: $e'};
    }
  }

  /// Agrega una pintura a una paleta existente mediante API
  /// Adds a paint to an existing palette via the API
  Future<Map<String, dynamic>> addPaintToPalette(
    Paint paint,
    String paletteId,
    String token,
  ) async {
    try {
      final baseUrl = '${Env.apiBaseUrl}';
      final url = Uri.parse('$baseUrl/palettes/$paletteId/paints');

      // 1) Determine the correct brand_id as before
      String brandId = _determineBrandIdForPaint(paint);

      if (!_brandManager.isOfficialBrandId(brandId)) {
        // Attempt to correct it using the brand name and set
        brandId = _brandManager.validateAndCorrectBrandId(
          brandId,
          paint.set != null ? '${paint.brand} ${paint.set}' : paint.brand,
        );
      }

      // 2) Build the payload as an array (even if only one item)
      final List<Map<String, dynamic>> payload = [
        {'paint_id': paint.id, 'brand_id': brandId},
      ];

      // 3) Send the POST with the array as the body
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      // 4) Parse the response just like before
      Map<String, dynamic> responseData = {};
      if (response.body.isNotEmpty) {
        try {
          responseData = json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          responseData = {'error': 'Invalid JSON response: ${response.body}'};
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Paint added to palette successfully',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to add paint to palette (${response.statusCode})',
          'error': responseData,
          'raw_response': response.body,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Agrega una pintura a la wishlist usando el endpoint directo
  Future<Map<String, dynamic>> addToWishlistDirect(
    Paint paint,
    int priority,
    String userId,
  ) async {
    try {
      if (paint == null) {
        return {'success': false, 'message': 'Paint object is null'};
      }

      // Get Firebase Auth token instead of using userId
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final token = await user.getIdToken();
      final baseUrl = '${Env.apiBaseUrl}';
      final url = Uri.parse('$baseUrl/wishlist');

      String brandId = _determineBrandIdForPaint(paint);

      if (brandId == null || brandId.isEmpty) {
        if (_brandManager.isOfficialBrandId(brandId)) {
          // Brand ID is valid
        } else {
          if (brandId.contains('Army') ||
              brandId.toLowerCase().contains('warpaint')) {
            brandId = 'Army_Painter';
          } else if (brandId.contains('Citadel')) {
            brandId = 'Citadel_Colour';
          }
        }
      }

      final requestBody = {
        "paint_id": paint.id,
        "brand_id": brandId,
        "type": "favorite",
        "priority": priority,
      };

      debugPrint('🌐 Sending wishlist request to: $url');
      debugPrint('📦 Request body: ${jsonEncode(requestBody)}');
      debugPrint('🔑 Using brand_id: $brandId for paint: ${paint.name}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Use proper auth header
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      Map<String, dynamic> responseData = {};
      if (response.body != null && response.body.isNotEmpty) {
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          responseData = {'error': 'Invalid JSON response: ${response.body}'};
        }
      }

      if (response.statusCode == 500 &&
          responseData['message'] != null &&
          responseData['message'].toString().contains(
            'Paint is already in the wishlist',
          )) {
        _wishlist[paint.id] = {
          'isPriority': priority > 0,
          'addedAt': DateTime.now(),
        };

        debugPrint('✅ Paint already in wishlist: ${paint.name}');
        return {
          'success': true,
          'id': 'already-exists',
          'message': 'Paint is already in your wishlist',
          'alreadyExists': true,
          'response': responseData,
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _wishlist[paint.id] = {
          'isPriority': priority > 0,
          'addedAt': DateTime.now(),
        };

        debugPrint('✅ Paint added to wishlist successfully: ${paint.name}');
        return {
          'success': true,
          'id': responseData['id'] ?? 'unknown-id',
          'message': 'Pintura añadida a wishlist con éxito',
          'response': responseData,
        };
      } else {
        debugPrint(
          '❌ Failed to add to wishlist: ${response.statusCode} - ${response.body}',
        );
        return {
          'success': false,
          'message':
              'Error al añadir a wishlist. Código: ${response.statusCode}',
          'error': responseData,
          'raw_response': response.body,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception adding to wishlist: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error: $e',
        'stacktrace': '$stackTrace',
      };
    }
  }

  /// Obtener datos de las paletas para diagnosticar el formato de datos
  Future<Map<String, dynamic>> getPaletteData(String token) async {
    try {
      final baseUrl = '${Env.apiBaseUrl}';
      final url = Uri.parse('$baseUrl/palettes');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Failed to fetch palettes (${response.statusCode})',
          'raw_response': response.body,
        };
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);

      return {'success': true, 'data': jsonData};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Debug function to log palette data structure for inspection
  Future<void> debugPaletteData(String token) async {
    try {
      final baseUrl = '${Env.apiBaseUrl}';
      final url = Uri.parse('$baseUrl/palettes');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Debug function to log wishlist data structure for inspection
  Future<void> debugWishlistData(String token) async {
    try {
      final baseUrl = '${Env.apiBaseUrl}';
      final url = Uri.parse('$baseUrl/wishlist');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Debug function to analyze paint data being sent to the API when saving to a palette
  Future<Map<String, dynamic>> debugSavePaintToPalette(
    Paint paint,
    String paletteId,
    String token,
  ) async {
    try {
      final baseUrl = '${Env.apiBaseUrl}';
      final url = Uri.parse('$baseUrl/palettes/$paletteId/paints');

      String determinedBrandId = _determineBrandIdForPaint(paint);

      final Map<String, dynamic> requestBody = {
        'paint_id': paint.id,
        'brand_id': determinedBrandId,
      };

      return {
        'success': true,
        'paint_id': paint.id,
        'brand_id': determinedBrandId,
        'url': url.toString(),
        'simulated_request_body': requestBody,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error during analysis: $e'};
    }
  }

  /// Carga las marcas oficiales desde el API o desde la caché local
  Future<bool> loadOfficialBrands() async {
    try {
      // Si ya tenemos un proceso de carga en curso, esperamos a que termine
      if (_brandManager.isLoaded == false && _loadingBrandsCompleter != null) {
        return await _loadingBrandsCompleter!.future;
      }

      // Si las marcas ya están cargadas, simplemente retornamos éxito
      if (_brandManager.isLoaded) {
        return true;
      }

      // Iniciamos un nuevo proceso de carga
      _loadingBrandsCompleter = Completer<bool>();

      // Llamar al método initialize del BrandServiceManager
      final success = await _brandManager.initialize();

      if (success) {
        _loadingBrandsCompleter!.complete(true);
        return true;
      } else {
        _loadingBrandsCompleter!.complete(false);
        return false;
      }
    } catch (e) {
      if (_loadingBrandsCompleter != null &&
          !_loadingBrandsCompleter!.isCompleted) {
        _loadingBrandsCompleter!.complete(false);
      }
      return false;
    } finally {
      // Limpiamos el completer si es necesario
      if (_loadingBrandsCompleter != null &&
          !_loadingBrandsCompleter!.isCompleted) {
        _loadingBrandsCompleter!.complete(false);
      }
    }
  }

  /// Completer para manejar múltiples solicitudes de carga de marcas
  Completer<bool>? _loadingBrandsCompleter;

  /// Gets information about the current cache state
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_CACHE_KEY);
      final lastUpdate = prefs.getString(_LAST_CACHE_UPDATE_KEY);

      List<String> details = [];
      int count = 0;

      if (cacheData != null) {
        try {
          final Map<String, dynamic> cache = json.decode(cacheData);
          count = cache.length;

          // Add some sample entries as details
          cache.entries.take(10).forEach((entry) {
            details.add(
              '${entry.key}: ${entry.value['name']} (${entry.value['brand']})',
            );
          });

          if (count > 10) {
            details.add('... and ${count - 10} more paints');
          }
        } catch (e) {
          details.add('Error parsing cache: $e');
        }
      }

      return {'count': count, 'lastUpdated': lastUpdate, 'details': details};
    } catch (e) {
      return {
        'count': 0,
        'lastUpdated': null,
        'details': ['Error: $e'],
      };
    }
  }

  /// Clears the paint cache
  Future<bool> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_CACHE_KEY);
      await prefs.remove(_LAST_CACHE_UPDATE_KEY);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Loads all paints into the cache
  Future<bool> loadAllPaintsToCache() async {
    try {
      // Get all paints (this would be replaced with actual API call in production)
      final samplePaints = SampleData.getPaints();

      // Convert to a map for cache storage
      final Map<String, dynamic> cacheData = {};
      for (final paint in samplePaints) {
        cacheData[paint.id] = {
          'name': paint.name,
          'brand': paint.brand,
          'hex': paint.hex,
          'code': paint.code,
        };
      }

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_CACHE_KEY, json.encode(cacheData));
      await prefs.setString(
        _LAST_CACHE_UPDATE_KEY,
        DateTime.now().toIso8601String(),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getPalettes({
    required int page,
    int limit = 10,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final token = await user.getIdToken();

    final url = Uri.parse('${Env.apiBaseUrl}/palettes?page=$page&limit=$limit');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'x-user-uid': user.uid,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error cargando paletas: ${response.statusCode}');
    }

    final decoded = json.decode(response.body)['data'];
    final rawPalettes = decoded['palettes'] as List;
    final totalPages = decoded['totalPages'] as int;

    final palettes =
        rawPalettes
            .map(
              (js) => Palette.fromJson({
                'id': js['id'],
                'name': js['name'],
                'imagePath': js['image'],
                'colors':
                    (js['PaintSelections'] as List)
                        .map((s) => s['colorHex'] as String)
                        .toList(),
                'createdAt': js['created_at'],
                'paintSelections': js['PaintSelections'],
                'totalPaints': js['total_paints'],
                'createdAtText': js['created_at_text'],
              }),
            )
            .toList();

    return {'palettes': palettes, 'totalPages': totalPages};
  }
}
