import 'dart:async';

import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  /// Constructor
  PaintService() {
    _loadDemoData();
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
    return _userPalettes.where((palette) {
      // Simulamos la contención de la pintura para demo
      // En una implementación real, verificaríamos si la paleta contiene la pintura
      return palette.id.hashCode % 2 == paintId.hashCode % 2;
    }).toList();
  }

  /// Agrega una pintura al inventario
  Future<bool> addToInventory(
    Paint paint,
    int quantity, {
    String? note,
    InventoryEntryType type = InventoryEntryType.new_paint,
  }) async {
    // Simulamos una operación asíncrona
    await Future.delayed(const Duration(milliseconds: 300));

    _inventory[paint.id] = {
      'quantity': quantity,
      'note': note,
      'addedAt': DateTime.now(),
      'type': type.toString(),
    };

    return true;
  }

  /// Actualiza una pintura en el inventario
  Future<bool> updateInventory(
    Paint paint,
    int quantity, {
    String? note,
    InventoryEntryType? type,
  }) async {
    // Simulamos una operación asíncrona
    await Future.delayed(const Duration(milliseconds: 300));

    if (!_inventory.containsKey(paint.id)) {
      return false;
    }

    final entry = _inventory[paint.id]!;
    entry['quantity'] = quantity;

    if (note != null) {
      entry['note'] = note;
    }

    if (type != null) {
      entry['type'] = type.toString();
    }

    return true;
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
    final baseUrl = 'https://paints-api.reachu.io/api';

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
    String token,
  ) async {
    // final baseUrl = 'http://10.0.2.2:8000';

    final baseUrl = 'https://paints-api.reachu.io/api';
    final url = Uri.parse('$baseUrl/wishlist/$wishlistId');

    // Convierte el valor booleano a backend (0 = prioridad, -1 = quitar)
    final priorityValue = isPriority ? 0 : -1;

    final requestBody = {'priority': priorityValue};
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
    final baseUrl = 'https://paints-api.reachu.io/api';
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

  /// Obtiene las paletas del usuario
  List<Palette> getUserPalettes() {
    return _userPalettes;
  }

  /// Crea una nueva paleta
  Future<Palette> createPalette(String name, List<Color> colors) async {
    // Simulamos una operación asíncrona
    await Future.delayed(const Duration(milliseconds: 300));

    final palette = Palette(
      id: 'palette-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      imagePath: 'assets/images/placeholder.jpg',
      colors: colors,
      createdAt: DateTime.now(),
    );

    _userPalettes.add(palette);
    return palette;
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
      final baseUrl = 'https://paints-api.reachu.io/api';
      final url = Uri.parse('$baseUrl/wishlist');

      // Extraer brand_id del nombre de la marca o ID
      String brandId = 'Unknown_Brand';
      if (paint.brand != null && paint.brand.isNotEmpty) {
        brandId = paint.brand.replaceAll(' ', '_');
        if (paint.brand.toLowerCase() == 'citadel') {
          brandId = 'Citadel_Colour';
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
}
