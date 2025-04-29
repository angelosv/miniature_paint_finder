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
      if (success) {
        print('✅ Marcas oficiales inicializadas correctamente');
      } else {
        print('⚠️ No se pudieron inicializar las marcas oficiales');
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
    return _brandManager.determineBrandIdForPaint(paint);
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
      print('\n🔄 addToInventory → usando API real');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No hay usuario autenticado');
        return false;
      }

      final token = await user.getIdToken();
      final brandId = _determineBrandIdForPaint(paint);

      final url = Uri.parse('${Env.apiBaseUrl}/api/inventory');

      final body = {
        'brand_id': brandId,
        'paint_id': paint.id,
        'quantity': quantity,
        'notes': note ?? '',
      };

      print('📤 POST → $url');
      print('📦 Body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

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
      print('❌ Error en addToInventory: $e');
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
      print('\n🔄 updateInventory → usando API real');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No hay usuario autenticado');
        return false;
      }

      final token = await user.getIdToken();
      final url = Uri.parse('${Env.apiBaseUrl}/api/inventory/$inventoryId');

      final Map<String, dynamic> body = {'quantity': quantity};

      if (note != null && note.trim().isNotEmpty) {
        body['notes'] = note;
      }

      print('📤 PUT → $url');
      print('📦 Body: $body');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        // 🧠 Actualización local
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
      print('❌ Error en updateInventory: $e');
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
    final baseUrl = '${Env.apiBaseUrl}/api';

    final url = Uri.parse('$baseUrl/wishlist/$_id');

    print('📤 DELETE Wishlist request: $url');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        '📥 DELETE Wishlist response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200) {
        // Mantén actualizado el estado local
        if (_wishlist.containsKey(paintId)) {
          _wishlist.remove(paintId);
        }
        return true;
      } else {
        print(
          '❌ Error al eliminar de wishlist: Código ${response.statusCode}, Respuesta: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('⚠️ Excepción al eliminar de wishlist: $e');
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
    final baseUrl = '${Env.apiBaseUrl}/api';
    final url = Uri.parse('$baseUrl/wishlist/$wishlistId');

    // If priorityLevel is provided (0-4), use it as the priority value
    // Otherwise use the standard conversion (0 = priority, -1 = no priority)
    final int priorityValue = priorityLevel.clamp(0, 5);

    // The API expects a body with type and priority fields
    final requestBody = {'type': 'favorite', 'priority': priorityValue};

    print('📤 PATCH Wishlist priority request: $url');
    print('📤 Request body: ${jsonEncode(requestBody)}');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print(
        '📥 PATCH Wishlist priority response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200) {
        // Actualiza el estado local
        if (_wishlist.containsKey(paintId)) {
          _wishlist[paintId]!['isPriority'] = isPriority;
          _wishlist[paintId]!['priority'] = priorityValue;
        }
        return true;
      } else {
        print(
          '❌ Error actualizando prioridad: Código ${response.statusCode}, Respuesta: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('⚠️ Excepción al actualizar prioridad: $e');
      rethrow;
    }
  }

  /// Obtiene todas las pinturas de la wishlist
  Future<List<Map<String, dynamic>>> getWishlistPaints(String token) async {
    final baseUrl = '${Env.apiBaseUrl}/api';
    final url = Uri.parse('$baseUrl/wishlist');

    print('📤 GET Wishlist request: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 GET Wishlist response [${response.statusCode}]');

      if (response.statusCode != 200) {
        print(
          '❌ Error al obtener wishlist: Código ${response.statusCode}, Respuesta: ${response.body}',
        );
        throw Exception(
          'Failed to fetch wishlist (${response.statusCode}): ${response.body}',
        );
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);
      print('📊 Estructura de respuesta: ${jsonData.keys.toList()}');

      final List<dynamic> wishlist = jsonData['whitelist'] ?? [];
      print('📊 Total de elementos en la wishlist: ${wishlist.length}');

      final List<Map<String, dynamic>> result = [];
      int skippedCount = 0;
      int processedCount = 0;

      for (final item in wishlist) {
        // Skip items with missing data
        if (item == null) {
          skippedCount++;
          continue;
        }

        try {
          // Check if item has direct paint_id and brand_id vs nested paint and brand objects
          bool isDirectFormat =
              item['paint'] == null && item['paint_id'] != null;
          String paintId =
              isDirectFormat ? item['paint_id'] : item['paint']?['code'];
          String brandId =
              isDirectFormat ? item['brand_id'] : item['brand']?['name'];

          if (paintId == null || brandId == null) {
            print('⚠️ Skipping wishlist item with missing data: $item');
            skippedCount++;
            continue;
          }

          // In direct format case, we need to find the paint details
          if (isDirectFormat) {
            print('🔍 Processing direct format wishlist item: $item');

            // For direct format, we'll attempt to find the paint or create a placeholder
            final createdAt = item['created_at'];

            // Create a minimal Paint object with available information
            final Paint paint = Paint.fromHex(
              id: paintId,
              name: _getPaintNameFromId(paintId),
              brand: _formatBrandId(brandId),
              hex: '#9c27b0', // Default purple color
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
              print('⚠️ Error parsing date: $e');
              addedAt = DateTime.now(); // Fallback to current time
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
          }
          // Original format with nested paint and brand objects
          else if (item['paint'] != null && item['brand'] != null) {
            final paintJson = item['paint'];
            final brandJson = item['brand'];
            final createdAt = item['created_at'];

            // Parse hex to get rgb components
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
            print('⚠️ Skipping wishlist item with missing data: $item');
            skippedCount++;
          }
        } catch (e) {
          print('⚠️ Error processing wishlist item: $e');
          print('⚠️ Item data: $item');
          skippedCount++;
        }
      }

      // Ordenar por prioridad (null al final) y luego por fecha de agregado
      result.sort((a, b) {
        final aPriority = a['priority'] ?? 9999;
        final bPriority = b['priority'] ?? 9999;

        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }

        return (b['addedAt'] as DateTime).compareTo(a['addedAt'] as DateTime);
      });

      print('✅ Procesados $processedCount elementos de la wishlist');
      print('⚠️ Omitidos $skippedCount elementos de la wishlist');
      return result;
    } catch (e) {
      print('⚠️ Excepción al obtener la wishlist: $e');
      return []; // Return empty list instead of rethrowing
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
      final baseUrl = '${Env.apiBaseUrl}/api';
      final url = Uri.parse('$baseUrl/palettes');

      print('🎨 Creating new palette via API');
      print('- Palette name: $name');
      print('- Colors count: ${colors.length}');

      // Prepare color data in format expected by API
      List<Map<String, dynamic>> colorData =
          colors.map((color) {
            // Convert Flutter Color to hex string
            final String hex = '#${color.value.toRadixString(16).substring(2)}';
            final r = color.red;
            final g = color.green;
            final b = color.blue;

            return {'hex': hex, 'r': r, 'g': g, 'b': b};
          }).toList();

      // Create request body
      final Map<String, dynamic> requestBody = {
        'name': name,
        'colors': colorData,
      };

      print('- Request URL: $url');
      print('- Request body: ${json.encode(requestBody)}');
      print(
        '- Request headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}',
      );

      // Make the API call
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('- API response status: ${response.statusCode}');
      print('- API response body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData = {};
      if (response.body != null && response.body.isNotEmpty) {
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          print('- Error parsing response body: $e');
          responseData = {'error': 'Invalid JSON response: ${response.body}'};
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String paletteId = responseData['id'] ?? 'unknown-id';

        // Create a local copy of the palette
        final palette = Palette(
          id: paletteId,
          name: name,
          imagePath: 'assets/images/placeholder.jpg',
          colors: colors,
          createdAt: DateTime.now(),
        );

        // Add to local palettes
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
      print('- Exception creating palette: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Método de prueba de integración para diagnóstico
  Future<Map<String, dynamic>> testPaletteAndWishlistIntegration(
    Paint paint,
    String token,
  ) async {
    try {
      print('🧪 INICIANDO TEST DE INTEGRACIÓN 🧪');
      print('==================================');

      // 1. Verificar la estructura actual de wishlist
      print('\n📋 PASO 1: Verificando estructura de wishlist actual');
      await debugWishlistData(token);

      // 2. Verificar la estructura actual de paletas
      print('\n📋 PASO 2: Verificando estructura de paletas actual');
      await debugPaletteData(token);

      // 3. Crear una nueva paleta para pruebas
      print('\n📋 PASO 3: Creando nueva paleta de prueba');
      // Crear un color basado en la pintura
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
      print('✅ Palette created with ID: $paletteId');

      // 4. Simular añadir una pintura a la paleta para ver qué datos se enviarían
      print('\n📋 PASO 4: Simulando añadir pintura a paleta');
      final simulationResult = await debugSavePaintToPalette(
        paint,
        paletteId,
        token,
      );

      // 5. Añadir la pintura a la paleta
      print('\n📋 PASO 5: Añadiendo pintura a la paleta');
      final addToPaletteResult = await addPaintToPalette(
        paint,
        paletteId,
        token,
      );

      // 6. Intentar añadir la pintura a la wishlist
      print('\n📋 PASO 6: Añadiendo pintura a wishlist');
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
      print('❌ ERROR en test de integración: $e');
      return {'success': false, 'message': 'Error en test de integración: $e'};
    }
  }

  /// Función para diagnosticar y corregir problemas con los brand_id en una paleta existente
  Future<Map<String, dynamic>> diagnosePaletteItemBrands(
    String paletteId,
    String token,
  ) async {
    try {
      final baseUrl = '${Env.apiBaseUrl}/api';

      // 1. Primero, obtenemos los datos actuales de la paleta
      final url = Uri.parse('$baseUrl/palettes/$paletteId');
      print('🔧 DIAGNÓSTICO: Obteniendo datos de la paleta $paletteId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        print('❌ Error obteniendo datos de la paleta: ${response.statusCode}');
        return {
          'success': false,
          'message':
              'Error al obtener datos de la paleta: ${response.statusCode}',
          'raw_response': response.body,
        };
      }

      final data = json.decode(response.body);
      print('✅ Datos de paleta obtenidos correctamente');

      // 2. Analizar las pinturas de la paleta
      if (!data.containsKey('data') ||
          !data['data'].containsKey('palettes_paints')) {
        print('❌ Formato de datos de paleta incorrecto');
        return {
          'success': false,
          'message': 'Formato de datos de paleta incorrecto',
          'raw_response': data,
        };
      }

      final List paletteItems = data['data']['palettes_paints'];
      print('🔍 La paleta tiene ${paletteItems.length} pinturas');

      // Lista para almacenar los problemas encontrados
      final List<Map<String, dynamic>> itemsWithProblems = [];

      // 3. Verificar cada pintura
      for (final item in paletteItems) {
        final String paintId = item['paint_id'];
        final String currentBrandId = item['brand_id'];

        // Obtener datos completos de la pintura
        final Paint? paintResult = await _getPaintDetailsById(paintId);
        if (paintResult == null) {
          print('⚠️ No se pudo obtener detalles de la pintura $paintId');
          continue;
        }

        final Paint paint = paintResult; // Ya verificamos que no es null

        // Determinar el brand_id correcto según nuestra lógica
        final String correctBrandId = _determineBrandIdForPaint(paint);

        // Comprobar si hay discrepancia
        if (currentBrandId != correctBrandId) {
          print('⚠️ DISCREPANCIA DE BRAND_ID:');
          print('  - Paint ID: $paintId (${paint.name})');
          print('  - Brand ID actual: $currentBrandId');
          print('  - Brand ID correcto: $correctBrandId');

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

      // 4. Mostrar resumen
      if (itemsWithProblems.isEmpty) {
        print('✅ No se encontraron problemas de brand_id en la paleta');
      } else {
        print(
          '⚠️ Se encontraron ${itemsWithProblems.length} pinturas con problemas de brand_id',
        );

        // Si quieres intentar corregir automáticamente, aquí iría el código
        // para enviar las correcciones al API
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
      print('❌ Error durante el diagnóstico: $e');
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
      print('❌ Error obteniendo detalles de la pintura $paintId: $e');
      return null;
    }
  }

  /// Función para corregir específicamente los problemas de Army Painter en una paleta
  Future<Map<String, dynamic>> fixArmyPainterInPalette(
    String paletteId,
    String token,
  ) async {
    try {
      final baseUrl = '${Env.apiBaseUrl}/api';

      // 1. Primero, obtenemos los datos actuales de la paleta
      final getUrl = Uri.parse('$baseUrl/palettes/$paletteId');
      print('🔧 REPARACIÓN: Obteniendo datos de la paleta $paletteId');

      final getResponse = await http.get(
        getUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (getResponse.statusCode != 200) {
        print(
          '❌ Error obteniendo datos de la paleta: ${getResponse.statusCode}',
        );
        return {
          'success': false,
          'message':
              'Error al obtener datos de la paleta: ${getResponse.statusCode}',
          'raw_response': getResponse.body,
        };
      }

      final data = json.decode(getResponse.body);
      print('✅ Datos de paleta obtenidos correctamente');

      // 2. Analizar las pinturas de la paleta
      if (!data.containsKey('data') ||
          !data['data'].containsKey('palettes_paints')) {
        print('❌ Formato de datos de paleta incorrecto');
        return {
          'success': false,
          'message': 'Formato de datos de paleta incorrecto',
          'raw_response': data,
        };
      }

      final List paletteItems = data['data']['palettes_paints'];
      print('🔍 La paleta tiene ${paletteItems.length} pinturas');

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
          print('⚠️ Pinturas de Army Painter con brand_id incorrecto:');
          print('  - Item ID: $itemId');
          print('  - Paint ID: $paintId');
          print('  - Brand ID actual: $currentBrandId');

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
        print(
          '✅ No se encontraron pinturas de Army Painter con brand_id incorrecto',
        );
        return {
          'success': true,
          'message': 'No se encontraron pinturas que corregir',
          'items_to_fix': itemsToFix,
        };
      }

      print('🔧 Corrigiendo ${itemsToFix.length} pinturas de Army Painter');

      for (final item in itemsToFix) {
        final itemId = item['id'];
        final updateUrl = Uri.parse(
          '$baseUrl/palettes/$paletteId/paints/$itemId',
        );

        // Preparar los datos para actualizar
        final updateBody = {'brand_id': 'Army_Painter'};

        print('🔄 Actualizando pintura $itemId');
        print('- URL: $updateUrl');
        print('- Body: ${json.encode(updateBody)}');

        try {
          final updateResponse = await http.patch(
            updateUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(updateBody),
          );

          print('- Respuesta: ${updateResponse.statusCode}');
          print('- Cuerpo: ${updateResponse.body}');

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
          print('❌ Error actualizando pintura $itemId: $e');
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
      print('❌ Error durante la reparación: $e');
      return {'success': false, 'message': 'Error durante la reparación: $e'};
    }
  }

  /// Imprime diagnóstico de las marcas oficiales cargadas
  void printBrandDiagnostics() {
    print('\n🔍 DIAGNÓSTICO DE MARCAS OFICIALES 🔍');
    print('===================================');

    if (!_brandManager.isLoaded) {
      print('⚠️ No hay marcas oficiales cargadas');
      print('Intentando cargar marcas desde API...');

      _brandManager.initialize().then((success) {
        if (success) {
          _printLoadedBrands();
        } else {
          print('❌ No se pudieron cargar las marcas oficiales');
        }
      });

      return;
    }

    _printLoadedBrands();
  }

  /// Método auxiliar para imprimir las marcas cargadas
  void _printLoadedBrands() {
    print('\n✅ Marcas oficiales cargadas');

    // Obtener todos los brand IDs
    final List<String> brandIds = _brandManager.getAllBrandIds();
    print('\nTotal de marcas oficiales: ${brandIds.length}');

    // Imprimir mapeo directo ordenado alfabéticamente
    final sortedBrandIds = List<String>.from(brandIds)..sort();
    print('\nMapeo directo (ID → Nombre):');
    for (final id in sortedBrandIds.take(10)) {
      final name = _brandManager.getBrandName(id);
      print('  - $id → ${name ?? "Sin nombre"}');
    }

    if (sortedBrandIds.length > 10) {
      print('  - ... y ${sortedBrandIds.length - 10} más ...');
    }

    // Mostrar información de marcas comunes
    print('\nEstado de marcas comunes:');
    final commonBrands = [
      'army painter',
      'the army painter',
      'warpaints',
      'citadel',
      'citadel colour',
      'vallejo',
      'ak interactive',
    ];

    for (final brand in commonBrands) {
      final String? brandId = _brandManager.getBrandId(brand);
      if (brandId != null) {
        print(
          '  ✓ "$brand" → $brandId (${_brandManager.getBrandName(brandId)})',
        );
      } else {
        print('  ✗ "$brand" no tiene mapeo directo');
      }
    }

    print('\n===================================\n');
  }

  /// Valida si un brand_id es oficial y retorna el id correcto o null
  String? validateBrandId(String brandId) {
    // Verificar si ya es un ID oficial
    if (_brandManager.isOfficialBrandId(brandId)) {
      return brandId;
    }

    // Intentar obtener el ID correcto usando el servicio
    return _brandManager.getBrandId(brandId);
  }

  /// Repara problemas de marcas en paletas usando la lista oficial
  Future<Map<String, dynamic>> repairPaletteBrandsWithOfficialList(
    String paletteId,
    String token,
  ) async {
    try {
      // 0. Asegurar que tenemos las marcas oficiales cargadas
      if (!_brandManager.isLoaded) {
        print('🏭 Ya hay una carga de marcas en curso, esperando...');
        final loaded = await loadOfficialBrands();
        if (!loaded) {
          return {
            'success': false,
            'message': 'No se pudieron cargar las marcas oficiales',
          };
        }
      }

      print(
        '🔧 REPARACIÓN AVANZADA: Corrigiendo marcas en paleta $paletteId usando lista oficial',
      );

      final baseUrl = '${Env.apiBaseUrl}/api';

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
        print(
          '❌ Error obteniendo datos de la paleta: ${getResponse.statusCode}',
        );
        return {
          'success': false,
          'message':
              'Error al obtener datos de la paleta: ${getResponse.statusCode}',
          'raw_response': getResponse.body,
        };
      }

      final data = json.decode(getResponse.body);
      print('✅ Datos de paleta obtenidos correctamente');

      // 3. Verificar si la paleta contiene pinturas de Army Painter
      if (!data.containsKey('data') ||
          !data['data'].containsKey('palettes_paints')) {
        print('❌ Formato de datos de paleta incorrecto');
        return {
          'success': false,
          'message': 'Formato de datos de paleta incorrecto',
          'raw_response': data,
        };
      }

      final List paletteItems = data['data']['palettes_paints'];
      print('🔍 La paleta tiene ${paletteItems.length} pinturas');

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
          print('⚠️ Pinturas de Army Painter con brand_id incorrecto:');
          print('  - Item ID: $itemId');
          print('  - Paint ID: $paintId');
          print('  - Brand ID actual: $currentBrandId');

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
        print(
          '✅ No se encontraron pinturas de Army Painter con brand_id incorrecto',
        );
        return {
          'success': true,
          'message': 'No se encontraron pinturas que corregir',
          'items_to_fix': itemsToFix,
        };
      }

      print('🔧 Corrigiendo ${itemsToFix.length} pinturas de Army Painter');

      for (final item in itemsToFix) {
        final itemId = item['id'];
        final updateUrl = Uri.parse(
          '$baseUrl/palettes/$paletteId/paints/$itemId',
        );

        // Preparar los datos para actualizar
        final updateBody = {'brand_id': 'Army_Painter'};

        print('🔄 Actualizando pintura $itemId');
        print('- URL: $updateUrl');
        print('- Body: ${json.encode(updateBody)}');

        try {
          final updateResponse = await http.patch(
            updateUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(updateBody),
          );

          print('- Respuesta: ${updateResponse.statusCode}');
          print('- Cuerpo: ${updateResponse.body}');

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
          print('❌ Error actualizando pintura $itemId: $e');
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
      print('❌ Error durante la reparación: $e');
      return {'success': false, 'message': 'Error durante la reparación: $e'};
    }
  }

  /// Agrega una pintura a una paleta existente mediante API
  Future<Map<String, dynamic>> addPaintToPalette(
    Paint paint,
    String paletteId,
    String token,
  ) async {
    try {
      final baseUrl = '${Env.apiBaseUrl}/api';
      final url = Uri.parse('$baseUrl/palettes/$paletteId/paints');

      print('🎨 Adding paint to palette via API');
      print('- Paint: ${paint.toJson()}');
      print('- Palette ID: $paletteId');
      if (paint.set != null) {
        print('- Paint set: "${paint.set}"');
      }

      // Determine correct brand_id using our helper method for consistency
      String brandId = _determineBrandIdForPaint(paint);
      print('- Determined brand_id: $brandId');

      // Verificar si el brand_id es válido usando BrandService
      if (!_brandManager.isOfficialBrandId(brandId)) {
        // Intentar corregir según el nombre de la marca y el set
        brandId = _brandManager.validateAndCorrectBrandId(
          brandId,
          paint.set != null ? '${paint.brand} ${paint.set}' : paint.brand,
        );

        print('- Corrected brand_id: $brandId');
      } else {
        print(
          '✓ Brand_id validado: $brandId (${_brandManager.getBrandName(brandId)})',
        );
      }

      // Create request body with the corrected brand_id
      final Map<String, dynamic> requestBody = {
        'paint_id': paint.id,
        'brand_id': brandId,
      };

      print('- Request URL: $url');
      print('- Request body: ${json.encode(requestBody)}');
      print(
        '- Request headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}',
      );

      // Make the actual API call
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('- API response status: ${response.statusCode}');
      print('- API response body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData = {};
      if (response.body != null && response.body.isNotEmpty) {
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          print('- Error parsing response body: $e');
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
        // Si el error es de brand_id que no existe, imprimir información de debug adicional
        if (responseData['message'] != null &&
            responseData['message'].toString().contains(
              'Brand does not exist',
            )) {
          print('❌ ERROR CRÍTICO DE BRAND_ID:');
          print('❌ Paint ID: ${paint.id}');
          print('❌ Brand original: ${paint.brand}');
          print('❌ Set original: ${paint.set}');
          print('❌ Brand ID enviado: ${brandId}');
          print(
            '❌ Marcas oficiales disponibles: ${_brandManager.getAllBrandIds().join(", ")}',
          );
          print(
            '❌ El backend no reconoce este brand_id. Debe ser uno de los brands soportados.',
          );
        }

        return {
          'success': false,
          'message': 'Failed to add paint to palette (${response.statusCode})',
          'error': responseData,
          'raw_response': response.body,
        };
      }
    } catch (e) {
      print('- Exception adding paint to palette: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Agrega una pintura a la wishlist usando el endpoint directo
  Future<Map<String, dynamic>> addToWishlistDirect(
    Paint paint,
    int priority,
    String userId,
  ) async {
    // Debug log the full request parameters
    print('📝 addToWishlistDirect request parameters:');
    print('- Paint: ${paint.toJson()}');
    print('- Priority: $priority');
    print('- User ID: $userId');
    print('- Original brand name: "${paint.brand}"');
    print('- Original paint ID: "${paint.id}"');
    if (paint.set != null) {
      print('- Paint set: "${paint.set}"');
    }

    try {
      if (paint == null) {
        print('❌ Error: Paint object is null');
        return {'success': false, 'message': 'Paint object is null'};
      }

      if (userId == null || userId.isEmpty) {
        print('❌ Error: User ID is null or empty');
        return {'success': false, 'message': 'User ID is required'};
      }

      // Ensure we're using the correct API endpoint
      final baseUrl = '${Env.apiBaseUrl}/api';
      final url = Uri.parse('$baseUrl/wishlist');

      // Determine brand ID using our consistent helper method
      String brandId = _determineBrandIdForPaint(paint);
      print('- Determined brand_id: $brandId');

      // Verificar si el brand_id está entre las marcas oficiales conocidas
      if (_brandManager.isOfficialBrandId(brandId)) {
        print(
          '✓ Brand_id validado: $brandId (${_brandManager.getBrandName(brandId)})',
        );
      } else {
        // Si no es una marca oficial, forzar override para ciertos casos conocidos
        if (brandId.contains('Army') ||
            brandId.toLowerCase().contains('warpaint')) {
          print('⚠️ Brand_id no oficial, corrigiendo: $brandId → Army_Painter');
          brandId = 'Army_Painter';
        } else if (brandId.contains('Citadel')) {
          print(
            '⚠️ Brand_id no oficial, corrigiendo: $brandId → Citadel_Colour',
          );
          brandId = 'Citadel_Colour';
        } else {
          print(
            '⚠️ Advertencia: brand_id "$brandId" no está en la lista oficial',
          );
        }
      }

      // Create request body EXACTLY as required
      final requestBody = {
        "paint_id": paint.id,
        "brand_id": brandId,
        "type": "favorite",
        "priority": priority,
      };

      print('📤 POST Add to Wishlist direct request: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');
      print(
        '📤 Request headers: {"Content-Type": "application/json", "x-user-uid": "$userId"}',
      );

      // Ensure we're using the POST method with correct headers
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'x-user-uid': userId},
        body: jsonEncode(requestBody),
      );

      print('📥 Direct API response status: ${response.statusCode}');
      print('📥 Direct API response body: ${response.body}');

      // Parse response safely
      Map<String, dynamic> responseData = {};
      if (response.body != null && response.body.isNotEmpty) {
        try {
          responseData = json.decode(response.body);
          print('📥 Parsed response data: $responseData');
        } catch (e) {
          print('❌ Error parsing response body: $e');
          responseData = {'error': 'Invalid JSON response: ${response.body}'};
        }
      }

      // Handle the case when paint is already in wishlist (treat as success)
      if (response.statusCode == 500 &&
          responseData['message'] != null &&
          responseData['message'].toString().contains(
            'Paint is already in the wishlist',
          )) {
        print('📝 Paint is already in wishlist, treating as success');

        // Update local wishlist
        _wishlist[paint.id] = {
          'isPriority': priority > 0,
          'addedAt': DateTime.now(),
        };

        return {
          'success': true,
          'id': 'already-exists',
          'message': 'Paint is already in your wishlist',
          'alreadyExists': true,
          'response': responseData,
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Actualizar wishlist local para mantener consistencia
        _wishlist[paint.id] = {
          'isPriority': priority > 0,
          'addedAt': DateTime.now(),
        };

        return {
          'success': true,
          'id': responseData['id'] ?? 'unknown-id',
          'message': 'Pintura añadida a wishlist con éxito',
          'response': responseData,
        };
      } else {
        // Si el error es de brand_id que no existe, imprimir información de debug adicional
        if (responseData['message'] != null &&
            responseData['message'].toString().contains(
              'Brand does not exist',
            )) {
          print('❌ ERROR CRÍTICO DE BRAND_ID:');
          print('❌ Paint ID: ${paint.id}');
          print('❌ Brand original: ${paint.brand}');
          print('❌ Set original: ${paint.set}');
          print('❌ Brand ID enviado: ${brandId}');
          print(
            '❌ Marcas oficiales disponibles: ${_brandManager.getAllBrandIds().join(", ")}',
          );
          print(
            '❌ El backend no reconoce este brand_id. Debe ser uno de los brands soportados.',
          );
        }

        return {
          'success': false,
          'message':
              'Error al añadir a wishlist. Código: ${response.statusCode}',
          'error': responseData,
          'raw_response': response.body,
        };
      }
    } catch (e, stackTrace) {
      print('⚠️ Excepción al añadir a wishlist directamente: $e');
      print('⚠️ StackTrace: $stackTrace');
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
      final baseUrl = '${Env.apiBaseUrl}/api';
      final url = Uri.parse('$baseUrl/palettes');

      print('📤 GET Palettes request: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 GET Palettes response [${response.statusCode}]');

      if (response.statusCode != 200) {
        print(
          '❌ Error al obtener paletas: Código ${response.statusCode}, Respuesta: ${response.body}',
        );
        return {
          'success': false,
          'message': 'Failed to fetch palettes (${response.statusCode})',
          'raw_response': response.body,
        };
      }

      // Parse and log the palette data to help diagnose
      final Map<String, dynamic> jsonData = json.decode(response.body);
      print('📊 Raw palette response structure: ${jsonData.keys.toList()}');

      // Log some sample data if available
      if (jsonData.containsKey('palettes') &&
          jsonData['palettes'] is List &&
          jsonData['palettes'].isNotEmpty) {
        final List<dynamic> palettes = jsonData['palettes'];
        print('📊 Total palettes: ${palettes.length}');

        // Log details of first palette
        if (palettes.isNotEmpty) {
          final firstPalette = palettes[0];
          print('📊 Sample palette structure: ${firstPalette.keys.toList()}');

          // Log paint details if available
          if (firstPalette.containsKey('paints') &&
              firstPalette['paints'] is List &&
              firstPalette['paints'].isNotEmpty) {
            final List<dynamic> paints = firstPalette['paints'];
            print('📊 Sample palette paint count: ${paints.length}');

            if (paints.isNotEmpty) {
              final firstPaint = paints[0];
              print(
                '📊 Sample paint data structure: ${firstPaint.keys.toList()}',
              );
              print('📊 Sample paint data: $firstPaint');

              // Log details about brand and paint fields
              if (firstPaint.containsKey('brand_id')) {
                print('📊 Sample paint brand_id: ${firstPaint['brand_id']}');
              }
              if (firstPaint.containsKey('brand')) {
                print('📊 Sample paint brand object: ${firstPaint['brand']}');
              }
              if (firstPaint.containsKey('paint_id')) {
                print('📊 Sample paint paint_id: ${firstPaint['paint_id']}');
              }
              if (firstPaint.containsKey('paint')) {
                print('📊 Sample paint paint object: ${firstPaint['paint']}');
              }
            }
          }
        }
      }

      return {'success': true, 'data': jsonData};
    } catch (e) {
      print('⚠️ Excepción al obtener las paletas: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Debug function to log palette data structure for inspection
  Future<void> debugPaletteData(String token) async {
    try {
      final baseUrl = '${Env.apiBaseUrl}/api';
      final url = Uri.parse('$baseUrl/palettes');

      print('🔍 DEBUG: Requesting palette data from $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔍 DEBUG: Palette API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('🔍 DEBUG: Palette response keys: ${data.keys.toList()}');

        // Check if we have palettes in the response
        if (data.containsKey('palettes') && data['palettes'] is List) {
          final List palettes = data['palettes'];
          print('🔍 DEBUG: Found ${palettes.length} palettes');

          if (palettes.isNotEmpty) {
            // Log data for the first palette
            final firstPalette = palettes[0];
            print(
              '🔍 DEBUG: First palette keys: ${firstPalette.keys.toList()}',
            );
            print('🔍 DEBUG: First palette ID: ${firstPalette['id']}');
            print('🔍 DEBUG: First palette name: ${firstPalette['name']}');

            // Check if we have paints in the palette
            if (firstPalette.containsKey('paints') &&
                firstPalette['paints'] is List) {
              final List paints = firstPalette['paints'];
              print('🔍 DEBUG: First palette has ${paints.length} paints');

              if (paints.isNotEmpty) {
                final firstPaint = paints[0];
                print('🔍 DEBUG: First paint in palette - complete data:');
                print(json.encode(firstPaint));

                // Look for brand information
                if (firstPaint.containsKey('brand_id')) {
                  print(
                    '🔍 DEBUG: Paint has brand_id: ${firstPaint['brand_id']}',
                  );
                } else {
                  print('🔍 DEBUG: Paint does NOT have brand_id field');
                }

                if (firstPaint.containsKey('brand')) {
                  print(
                    '🔍 DEBUG: Paint has brand object: ${firstPaint['brand']}',
                  );
                  if (firstPaint['brand'] is Map) {
                    final brandObj = firstPaint['brand'];
                    print(
                      '🔍 DEBUG: Brand object keys: ${brandObj.keys.toList()}',
                    );
                    if (brandObj.containsKey('name')) {
                      print('🔍 DEBUG: Brand name: ${brandObj['name']}');
                    }
                  }
                } else {
                  print('🔍 DEBUG: Paint does NOT have brand object');
                }

                // Look for paint information
                if (firstPaint.containsKey('paint_id')) {
                  print(
                    '🔍 DEBUG: Paint has paint_id: ${firstPaint['paint_id']}',
                  );
                } else {
                  print('🔍 DEBUG: Paint does NOT have paint_id field');
                }

                if (firstPaint.containsKey('paint')) {
                  print(
                    '🔍 DEBUG: Paint has paint object: ${firstPaint['paint']}',
                  );
                  if (firstPaint['paint'] is Map) {
                    final paintObj = firstPaint['paint'];
                    print(
                      '🔍 DEBUG: Paint object keys: ${paintObj.keys.toList()}',
                    );
                    if (paintObj.containsKey('name')) {
                      print('🔍 DEBUG: Paint name: ${paintObj['name']}');
                    }
                    if (paintObj.containsKey('code')) {
                      print('🔍 DEBUG: Paint code: ${paintObj['code']}');
                    }
                  }
                } else {
                  print('🔍 DEBUG: Paint does NOT have paint object');
                }
              }
            }
          }
        }
      } else {
        print('🔍 ERROR: Failed to get palette data - ${response.statusCode}');
        print('🔍 ERROR: Response body: ${response.body}');
      }
    } catch (e) {
      print('🔍 EXCEPTION: $e');
    }
  }

  /// Debug function to log wishlist data structure for inspection
  Future<void> debugWishlistData(String token) async {
    try {
      final baseUrl = '${Env.apiBaseUrl}/api';
      final url = Uri.parse('$baseUrl/wishlist');

      print('🔎 DEBUG WISHLIST: Requesting wishlist data from $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔎 DEBUG WISHLIST: API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('🔎 DEBUG WISHLIST: Response keys: ${data.keys.toList()}');

        // Check if we have whitelist items in the response
        if (data.containsKey('whitelist') && data['whitelist'] is List) {
          final List whitelist = data['whitelist'];
          print(
            '🔎 DEBUG WISHLIST: Found ${whitelist.length} items in wishlist',
          );

          if (whitelist.isNotEmpty) {
            // Log the first 3 items to see the pattern
            final int itemsToLog = whitelist.length > 3 ? 3 : whitelist.length;

            for (int i = 0; i < itemsToLog; i++) {
              final item = whitelist[i];
              print('🔎 DEBUG WISHLIST: Item #${i + 1} - complete data:');
              print(json.encode(item));

              print(
                '🔎 DEBUG WISHLIST: Item #${i + 1} keys: ${item.keys.toList()}',
              );

              // Check for brand information
              if (item.containsKey('brand_id')) {
                print(
                  '🔎 DEBUG WISHLIST: Item #${i + 1} has brand_id: ${item['brand_id']}',
                );
              } else {
                print(
                  '🔎 DEBUG WISHLIST: Item #${i + 1} does NOT have brand_id field',
                );
              }

              if (item.containsKey('brand')) {
                print(
                  '🔎 DEBUG WISHLIST: Item #${i + 1} has brand object: ${item['brand']}',
                );
                if (item['brand'] is Map) {
                  final brandObj = item['brand'];
                  print(
                    '🔎 DEBUG WISHLIST: Brand object keys: ${brandObj.keys.toList()}',
                  );
                  if (brandObj.containsKey('name')) {
                    print('🔎 DEBUG WISHLIST: Brand name: ${brandObj['name']}');
                  }
                }
              } else {
                print(
                  '🔎 DEBUG WISHLIST: Item #${i + 1} does NOT have brand object',
                );
              }

              // Check for paint information
              if (item.containsKey('paint_id')) {
                print(
                  '🔎 DEBUG WISHLIST: Item #${i + 1} has paint_id: ${item['paint_id']}',
                );
              } else {
                print(
                  '🔎 DEBUG WISHLIST: Item #${i + 1} does NOT have paint_id field',
                );
              }

              if (item.containsKey('paint')) {
                print(
                  '🔎 DEBUG WISHLIST: Item #${i + 1} has paint object: ${item['paint']}',
                );
                if (item['paint'] is Map) {
                  final paintObj = item['paint'];
                  print(
                    '🔎 DEBUG WISHLIST: Paint object keys: ${paintObj.keys.toList()}',
                  );
                  if (paintObj.containsKey('name')) {
                    print('🔎 DEBUG WISHLIST: Paint name: ${paintObj['name']}');
                  }
                  if (paintObj.containsKey('code')) {
                    print('🔎 DEBUG WISHLIST: Paint code: ${paintObj['code']}');
                  }
                }
              } else {
                print(
                  '🔎 DEBUG WISHLIST: Item #${i + 1} does NOT have paint object',
                );
              }

              if (item.containsKey('priority')) {
                print(
                  '🔎 DEBUG WISHLIST: Item #${i + 1} priority: ${item['priority']}',
                );
              }

              print('----------------------------------------------------');
            }

            // Log if there are different structures in the wishlist
            final Set<String> uniqueStructures = Set<String>();
            for (final item in whitelist) {
              final List<String> keys = List<String>.from(item.keys);
              keys.sort();
              uniqueStructures.add(keys.join(','));
            }

            print(
              '🔎 DEBUG WISHLIST: Number of unique data structures: ${uniqueStructures.length}',
            );
            int structureIndex = 1;
            for (final structure in uniqueStructures) {
              print(
                '🔎 DEBUG WISHLIST: Structure #$structureIndex: $structure',
              );
              structureIndex++;
            }
          }
        } else {
          print('🔎 DEBUG WISHLIST: No wishlist data found in response');
        }
      } else {
        print('🔎 ERROR: Failed to get wishlist data - ${response.statusCode}');
        print('🔎 ERROR: Response body: ${response.body}');
      }
    } catch (e) {
      print('🔎 EXCEPTION: $e');
    }
  }

  /// Debug function to analyze paint data being sent to the API when saving to a palette
  Future<Map<String, dynamic>> debugSavePaintToPalette(
    Paint paint,
    String paletteId,
    String token,
  ) async {
    try {
      final baseUrl = '${Env.apiBaseUrl}/api';
      final url = Uri.parse('$baseUrl/palettes/$paletteId/paints');

      print(
        '🔮 DEBUG PALETTE SAVE: Analysis of paint data before saving to palette',
      );
      print('🔮 Paint ID: ${paint.id}');
      print('🔮 Paint Name: ${paint.name}');
      print('🔮 Paint Brand: ${paint.brand}');
      print('🔮 Paint Code: ${paint.code}');
      print('🔮 Paint Full Data: ${paint.toJson()}');

      // Check what brand_id would be determined for this paint
      String determinedBrandId = _determineBrandIdForPaint(paint);
      print('🔮 Determined brand_id would be: $determinedBrandId');

      // Create what the request body would look like
      final Map<String, dynamic> requestBody = {
        'paint_id': paint.id,
        'brand_id': determinedBrandId,
      };

      print('🔮 Request body would be: ${json.encode(requestBody)}');
      print('🔮 Request URL would be: $url');
      print('🔮 Request method would be: POST');

      // Simulate what the actual request would do without sending it
      print('🔮 This is just a simulation, no actual API call is being made');

      return {
        'success': true,
        'paint_id': paint.id,
        'brand_id': determinedBrandId,
        'url': url.toString(),
        'simulated_request_body': requestBody,
      };
    } catch (e) {
      print('🔮 EXCEPTION during analysis: $e');
      return {'success': false, 'message': 'Error during analysis: $e'};
    }
  }

  /// Carga las marcas oficiales desde el API o desde la caché local
  Future<bool> loadOfficialBrands() async {
    try {
      // Si ya tenemos un proceso de carga en curso, esperamos a que termine
      if (_brandManager.isLoaded == false && _loadingBrandsCompleter != null) {
        print('🏭 Ya hay una carga de marcas en curso, esperando...');
        return await _loadingBrandsCompleter!.future;
      }

      // Si las marcas ya están cargadas, simplemente retornamos éxito
      if (_brandManager.isLoaded) {
        print('✅ Marcas ya cargadas previamente');
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
      print('❌ Error cargando marcas oficiales: $e');
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
      print('Error getting cache info: $e');
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
      print('Error clearing cache: $e');
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
      print('Error loading paints to cache: $e');
      return false;
    }
  }
}
